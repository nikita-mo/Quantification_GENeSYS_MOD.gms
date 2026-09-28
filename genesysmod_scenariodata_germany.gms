** GENeSYS-MOD - scenario data Germany (16 federal states) for the vertical-integration study
**
** Ported 2026-09-27 from the Ch5 file "genesysmod_scenariodata_de - Kopie.gms" (v3.1 era), decisions of 2026-09-27:
**   KEPT     nuclear exit; coal exit (incl. NRW 2030, domestic hard-coal mining 0 after 2020); buildings renovation inertia
**   ADDED    NECP capacity plans as LOWER limits on the 16-Laender sum (group-minimum mechanism), same values as the
**            Man0EUvRE project overlay uses for the EU run's DE node (there as equality);
**            Waermeplanungsgesetz district-heating rule on the national sum (>= 30 % renewables / unavoidable waste heat from 2030, >= 80 % from 2040)
**   DROPPED  everything tied to the sea nodes DE_Nord/DE_Baltic and the FEP offshore-region equations (data-side now);
**            Ch5 offshore max-capacity overrides for NI/SH/MV; Osterpaket/FEP equality equations; H2 import price-target
**            sensitivity and switch_central_h2; flat H2/gas import equations; power-sector net-zero 2035; 50 % RE heat;
**            sectoral non-increase of emissions (E13a); district-heating share equations for 2050;
**            reserve margin = 0; variable-cost floor and solar-thermal CF fix (both in core genesysmod_bounds.gms)
** Switch: --switch_de_policy=0 turns the NECP targets and the WPG rule off (coal/nuclear exits and inertia stay).
**
** Names updated from the v3.1 scheme: RES_* -> P_*, Heat_Low_Residential -> Heat_Buildings; CHP exclusion via subset tag.

$if not set switch_de_policy $setglobal switch_de_policy 1
* biomass import allowance for STANDALONE runs (default: on when the vertical integration is off, off when it is on)
$ifthen.bia not set switch_de_biomass_import_allowance
$ifthen.viflag %switch_vertical_integration% == 1
$setglobal switch_de_biomass_import_allowance 0
$else.viflag
$setglobal switch_de_biomass_import_allowance 1
$endif.viflag
$endif.bia

*
*##### Standalone runs: biomass import allowance (2026-09-28) #####
*
* The German biomass potential (709.7 PJ in 2018, national value split over the Laender) is below the biomass use implied
* by the researched 2018 production (about 750 PJ). In the European model Germany closes the gap with 276.3 PJ of biomass
* imports (EnVis NECP Essentials, 122-slice run, 2018: CH 112.2, FR 103.5, PL 44.8, AT 14.9, CZ 0.9 PJ). A standalone
* national model has no biomass import technology, so the EU-run import volume is added to the R_Wood potential of the
* border Laender of each partner, constant over the horizon (the island reference keeps the 2018 import level).
* Linked runs receive the biomass as exogenous trade and must run with the allowance off.
$ifthen.biomass %switch_de_biomass_import_allowance% == 1
parameter BiomassImportAllowance(r_full) 'EU-run 2018 biomass imports of DE assigned to the border Laender [PJ]' /
  DE_BW  146.7
  DE_RP   34.5
  DE_SL   34.5
  DE_BY   15.35
  DE_BB   14.933
  DE_MV   14.933
  DE_SN   15.383
/;
TotalTechnologyAnnualActivityUpperLimit(r,'R_Wood',y)$(BiomassImportAllowance(r)) = TotalTechnologyAnnualActivityUpperLimit(r,'R_Wood',y) + BiomassImportAllowance(r);
$endif.biomass

*
*##### Nuclear exit #####
*
TotalTechnologyAnnualActivityUpperLimit(r,'P_Nuclear',y)$(YearVal(y) >= 2025) = 0;
AvailabilityFactor(r,'P_Nuclear',y)$(YearVal(y) > 2020) = 0;

*
*##### Coal exit (Kohleverstromungsbeendigungsgesetz: 2038; Rhineland 2030) #####
*
AvailabilityFactor(r,'P_Coal_Lignite',y)$(YearVal(y) > 2035) = 0;
AvailabilityFactor('DE_NRW','P_Coal_Lignite',y)$(YearVal(y) > 2030) = 0;
AvailabilityFactor(r,'P_Coal_Hardcoal',y)$(YearVal(y) > 2035) = 0;
AvailabilityFactor(r,'CHP_Coal_Hardcoal',y)$(YearVal(y) > 2035) = 0;
AvailabilityFactor(r,'CHP_Coal_Lignite',y)$(YearVal(y) > 2035) = 0;
AvailabilityFactor('DE_NRW','CHP_Coal_Lignite',y)$(YearVal(y) > 2030) = 0;
AvailabilityFactor(r,'R_Coal_Hardcoal',y)$(YearVal(y) > 2020) = 0;
ProductionByTechnologyAnnual.fx('2040',t,'Power',r)$(sum(m,InputActivityRatio(r,t,'Hardcoal',m,'2040'))) = 0;
ProductionByTechnologyAnnual.fx('2040',t,'Power',r)$(sum(m,InputActivityRatio(r,t,'Lignite',m,'2040'))) = 0;

*
*##### Buildings: renovation inertia (Ch5) #####
*
parameter Renovierungsrate(y_full);
Renovierungsrate(y) = 0.015;
Renovierungsrate(y)$(YearVal(y) > 2020) = 0.035;
Renovierungsrate(y)$(YearVal(y) > 2030) = 0.045;
Renovierungsrate(y)$(YearVal(y) > 2040) = 0.065;
equation BuildingsInertia(REGION_FULL,TECHNOLOGY,YEAR_FULL);
BuildingsInertia(r,t,y)$(TagTechnologyToSector(t,'Buildings') and YearVal(y) > 2015 and not TagTechnologyToSubsets(t,'CHP'))..
  ProductionByTechnologyAnnual(y,t,'Heat_Buildings',r) =g= (1 - sum(yy$(YearVal(yy) <= YearVal(y)), Renovierungsrate(yy)*YearlyDifferenceMultiplier(yy-1)))*ProductionByTechnologyAnnual('2018',t,'Heat_Buildings',r);

$ifthen %switch_de_policy% == 1
*
*##### NECP capacity plans as lower limits on the national (16-Laender) sum #####
* Values = Man0EUvRE project overlay, NECPCapacityPlans('DE',...): power-supply technologies only.
*
TagRegionToSubsets(r,'DE_all') = 1;
TagTechnologyToSubsets(t,'NECP_Solar')$(TagTechnologyToSubsets(t,'Solar') and TagTechnologyToSubsets(t,'PowerSupply')) = 1;
TagTechnologyToSubsets(t,'NECP_Onshore')$(TagTechnologyToSubsets(t,'Onshore') and TagTechnologyToSubsets(t,'PowerSupply')) = 1;
TagTechnologyToSubsets(t,'NECP_Offshore')$(TagTechnologyToSubsets(t,'Offshore') and TagTechnologyToSubsets(t,'PowerSupply')) = 1;
option TechGroup < TagTechnologyToSubsets;
option RegionGroup < TagRegionToSubsets;
GroupTotalAnnualMinCapacity('NECP_Solar','DE_all','2025')    = 117.7;
GroupTotalAnnualMinCapacity('NECP_Solar','DE_all','2030')    = 215;
GroupTotalAnnualMinCapacity('NECP_Solar','DE_all','2040')    = 400;
GroupTotalAnnualMinCapacity('NECP_Onshore','DE_all','2025')  = 64;
GroupTotalAnnualMinCapacity('NECP_Onshore','DE_all','2030')  = 115;
GroupTotalAnnualMinCapacity('NECP_Onshore','DE_all','2040')  = 160;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_all','2025') = 9.215;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_all','2030') = 30;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_all','2035') = 40;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_all','2045') = 70;

*
*##### Waermeplanungsgesetz 2024, par. 29-30: renewable / unavoidable waste-heat share in district heating #####
* The law binds each network operator; the model has no networks. Applied to the NATIONAL sum (decision 2026-09-27:
* lenient proxy, allows regional heterogeneity): >= 30 % from 2030, >= 80 % from 2040.
* ASSUMPTION: waste-to-energy CHP counted at 50 % (biogenic share); heat pumps, geothermal, solar thermal, biomass CHP at 100 %.
*
parameter WPG_DH_Share(y_full);
WPG_DH_Share(y)$(YearVal(y) >= 2030) = 0.30;
WPG_DH_Share(y)$(YearVal(y) >= 2040) = 0.80;
parameter WPG_DH_Weight(t);
WPG_DH_Weight(t) = 0;
WPG_DH_Weight('HD_Geothermal') = 1;
WPG_DH_Weight('HD_Solar_Thermal') = 1;
WPG_DH_Weight('HD_Heatpump_ExcessHeat') = 1;
WPG_DH_Weight('HD_Heatpump_Air') = 1;
WPG_DH_Weight('CHP_Biomass_Solid') = 1;
WPG_DH_Weight('CHP_WasteToEnergy') = 0.5;
equation DE_WPG_DistrictHeatRenewableShare(YEAR_FULL);
DE_WPG_DistrictHeatRenewableShare(y)$(WPG_DH_Share(y))..
  sum((t,r), WPG_DH_Weight(t)*ProductionByTechnologyAnnual(y,t,'Heat_District',r)) =g= WPG_DH_Share(y)*sum((t,r), ProductionByTechnologyAnnual(y,t,'Heat_District',r));
$endif
