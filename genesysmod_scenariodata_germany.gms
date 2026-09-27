** GENeSYS-MOD - scenario data Germany (16 federal states) for the vertical-integration study
**
** Ported 2026-09-27 from the Ch5 file "genesysmod_scenariodata_de - Kopie.gms" (v3.1 era), decisions of 2026-09-27:
**   KEPT     nuclear exit; coal exit (incl. NRW 2030, domestic hard-coal mining 0 after 2020); buildings renovation inertia
**   ADDED    NECP capacity plans as LOWER limits on the 16-Laender sum (group-minimum mechanism), same values as the
**            Man0EUvRE project overlay uses for the EU run's DE node (there as equality);
**            Waermeplanungsgesetz district-heating rule (>= 30 % renewables / unavoidable waste heat from 2030, >= 80 % from 2040)
**   DROPPED  everything tied to the sea nodes DE_Nord/DE_Baltic and the FEP offshore-region equations (data-side now);
**            Ch5 offshore max-capacity overrides for NI/SH/MV; Osterpaket/FEP equality equations; H2 import price-target
**            sensitivity and switch_central_h2; flat H2/gas import equations; power-sector net-zero 2035; 50 % RE heat;
**            sectoral non-increase of emissions (E13a); district-heating share equations for 2050;
**            reserve margin = 0; variable-cost floor and solar-thermal CF fix (both in core genesysmod_bounds.gms)
** Switch: --switch_de_policy=0 turns the NECP targets and the WPG rule off (coal/nuclear exits and inertia stay).
**
** Technology names updated from the v3.1 scheme (RES_*) to the current scheme (P_*).

$if not set switch_de_policy $setglobal switch_de_policy 1

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
BuildingsInertia(r,t,y)$(TagTechnologyToSector(t,'Buildings') and YearVal(y) > 2015 and sum((tt)$(TagTechnologyToSubsets(tt,'CHP')),diag(t,tt)) = 0)..
  ProductionByTechnologyAnnual(y,t,'Heat_Low_Residential',r) =g= (1 - sum(yy$(YearVal(yy) <= YearVal(y)), Renovierungsrate(yy)*YearlyDifferenceMultiplier(yy-1)))*ProductionByTechnologyAnnual('2018',t,'Heat_Low_Residential',r);

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
* Applied per Land (proxy for "per network"): >= 30 % from 2030, >= 80 % from 2040.
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
equation DE_WPG_DistrictHeatRenewableShare(YEAR_FULL,REGION_FULL);
DE_WPG_DistrictHeatRenewableShare(y,r)$(WPG_DH_Share(y) and DistrictHeatDemand(r,y))..
  sum(t, WPG_DH_Weight(t)*ProductionByTechnologyAnnual(y,t,'Heat_District',r)) =g= WPG_DH_Share(y)*sum(t, ProductionByTechnologyAnnual(y,t,'Heat_District',r));
$endif
