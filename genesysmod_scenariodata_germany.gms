** Scenario data Germany (16 federal states), vertical-integration study

$if not set switch_de_policy $setglobal switch_de_policy 0

*##### Nuclear exit #####
TotalTechnologyAnnualActivityUpperLimit(r,'P_Nuclear',y)$(YearVal(y) >= 2025) = 0;
AvailabilityFactor(r,'P_Nuclear',y)$(YearVal(y) > 2020) = 0;

*##### Coal exit (Kohleverstromungsbeendigungsgesetz) #####
AvailabilityFactor(r,'P_Coal_Lignite',y)$(YearVal(y) > 2035) = 0;
AvailabilityFactor('DE_NRW','P_Coal_Lignite',y)$(YearVal(y) > 2030) = 0;
AvailabilityFactor(r,'P_Coal_Hardcoal',y)$(YearVal(y) > 2035) = 0;
AvailabilityFactor(r,'CHP_Coal_Hardcoal',y)$(YearVal(y) > 2035) = 0;
AvailabilityFactor(r,'CHP_Coal_Lignite',y)$(YearVal(y) > 2035) = 0;
AvailabilityFactor('DE_NRW','CHP_Coal_Lignite',y)$(YearVal(y) > 2030) = 0;
AvailabilityFactor(r,'R_Coal_Hardcoal',y)$(YearVal(y) > 2020) = 0;
ProductionByTechnologyAnnual.fx('2040',t,'Power',r)$(sum(m,InputActivityRatio(r,t,'Hardcoal',m,'2040'))) = 0;
ProductionByTechnologyAnnual.fx('2040',t,'Power',r)$(sum(m,InputActivityRatio(r,t,'Lignite',m,'2040'))) = 0;

*##### Buildings renovation inertia (assumption based on IWU 2018, Datenerhebung Wohngebaeudebestand 2016) #####
parameter Renovierungsrate(y_full);
Renovierungsrate(y) = 0.015;
Renovierungsrate(y)$(YearVal(y) > 2020) = 0.035;
Renovierungsrate(y)$(YearVal(y) > 2030) = 0.045;
Renovierungsrate(y)$(YearVal(y) > 2040) = 0.065;
equation BuildingsInertia(REGION_FULL,TECHNOLOGY,YEAR_FULL);
BuildingsInertia(r,t,y)$(TagTechnologyToSector(t,'Buildings') and YearVal(y) > 2015 and not TagTechnologyToSubsets(t,'CHP') and AvailabilityFactor(r,t,y) >= AvailabilityFactor(r,t,'2018'))..
  ProductionByTechnologyAnnual(y,t,'Heat_Buildings',r) =g= (1 - sum(yy$(YearVal(yy) <= YearVal(y)), Renovierungsrate(yy)*YearlyDifferenceMultiplier(yy-1)))*ProductionByTechnologyAnnual('2018',t,'Heat_Buildings',r);

*##### National group caps (BECCS, biomass imports) on the 16-Laender sum #####
GroupTotalAnnualMaxCapacity(tg,'DE_states',y)$GroupTotalAnnualMaxCapacity(tg,'DE',y) = GroupTotalAnnualMaxCapacity(tg,'DE',y);
option RegionGroup < TagRegionToSubsets;

*##### CCS only in high-temperature industry and BECCS #####
AvailabilityFactor(r,t,y)$(TagTechnologyToSubsets(t,'CCS')
                           and not TagTechnologyToSubsets(t,'BECCS')
                           and not (sameas(t,'HHI_BF_BOF_CCS') or sameas(t,'HHI_DRI_EAF_CCS'))) = 0;

*##### Fossil transport and gas-based steel in the phase-out smoothing #####
TagTechnologyToSubsets('PSNG_Rail_Conv','PhaseOutSet') = 1;
TagTechnologyToSubsets('FRT_Rail_Conv','PhaseOutSet') = 1;
TagTechnologyToSubsets('FRT_Ship_Conv','PhaseOutSet') = 1;
TagTechnologyToSubsets('PSNG_Air_Conv','PhaseOutSet') = 1;
TagTechnologyToSubsets('HHI_DRI_EAF','PhaseOutSet') = 1;

*##### 2025 as historic year: no power from technologies without production statistics #####
ProductionByTechnologyAnnual.fx('2025',t,'Power',r)$((TagTechnologyToSubsets(t,'PowerSupply') or TagTechnologyToSubsets(t,'CHP') or sameas(t,'CHP_WasteToEnergy')) and not RegionalBaseYearProduction(r,t,'Power','2025')) = 0;

*##### Emissions per sector and region are not allowed to increase; negative-emission technologies are not counted #####
parameter DE_NegativeEmission(TECHNOLOGY);
DE_NegativeEmission(t)$(smin((r,m,e,y), EmissionActivityRatio(r,t,m,e,y)) < 0) = 1;
equation E13a_SectoralEmissionReduction(y_full,EMISSION,SECTOR,REGION_FULL);
E13a_SectoralEmissionReduction(y,e,se,r)$(YearVal(y) > %year% and not sum((t,f), RegionalBaseYearProduction(r,t,f,y)))..
  sum(t$(TagTechnologyToSector(t,se) and not DE_NegativeEmission(t)), AnnualTechnologyEmission(y,t,e,r)) =l= sum(t$(TagTechnologyToSector(t,se) and not DE_NegativeEmission(t)), AnnualTechnologyEmission(y-1,t,e,r));

$ifthen %switch_de_policy% == 1
*##### NECP capacity floors on the national sum (EEG 2023 par. 4, WindSeeG par. 1) #####
TagTechnologyToSubsets(t,'NECP_Solar')$(TagTechnologyToSubsets(t,'Solar') and TagTechnologyToSubsets(t,'PowerSupply')) = 1;
TagTechnologyToSubsets(t,'NECP_Onshore')$(TagTechnologyToSubsets(t,'Onshore') and TagTechnologyToSubsets(t,'PowerSupply')) = 1;
TagTechnologyToSubsets(t,'NECP_Offshore')$(TagTechnologyToSubsets(t,'Offshore') and TagTechnologyToSubsets(t,'PowerSupply')) = 1;
TagTechnologyToSubsets('X_Electrolysis','NWS_Electrolysis') = 1;
option TechGroup < TagTechnologyToSubsets;
* new groups: no upper limit, as set for all other groups in genesysmod_bounds.gms
GroupTotalAnnualMaxCapacity(tg,rg,y)$(not GroupTotalAnnualMaxCapacity(tg,rg,y)) = 999999;
GroupTotalAnnualMinCapacity('NECP_Solar','DE_states','2025')    = 117.7;
GroupTotalAnnualMinCapacity('NECP_Solar','DE_states','2030')    = 215;
GroupTotalAnnualMinCapacity('NECP_Solar','DE_states','2035')    = 309;
GroupTotalAnnualMinCapacity('NECP_Solar','DE_states','2040')    = 400;
GroupTotalAnnualMinCapacity('NECP_Solar','DE_states',y)$(YearVal(y) > 2040)    = 400;
GroupTotalAnnualMinCapacity('NECP_Onshore','DE_states','2025')  = 64;
GroupTotalAnnualMinCapacity('NECP_Onshore','DE_states','2030')  = 115;
GroupTotalAnnualMinCapacity('NECP_Onshore','DE_states','2035')  = 157;
GroupTotalAnnualMinCapacity('NECP_Onshore','DE_states','2040')  = 160;
GroupTotalAnnualMinCapacity('NECP_Onshore','DE_states',y)$(YearVal(y) > 2040)  = 160;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_states','2025') = 9.215;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_states','2030') = 30;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_states','2035') = 40;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_states','2040') = 40;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_states','2045') = 70;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_states',y)$(YearVal(y) > 2045) = 70;

*##### Nationale Wasserstoffstrategie 2023: 10 GW of electrolysis (electric input) from 2030 on the national sum #####
GroupTotalAnnualMinCapacity('NWS_Electrolysis','DE_states',y)$(YearVal(y) >= 2030) = 10/InputActivityRatio('DE_BY','X_Electrolysis','Power','1','2030');

*##### Waermeplanungsgesetz par. 29-31: renewable and waste-heat share of district heating on the national sum, fully from 2045 #####
parameter WPG_DH_Share(y_full);
WPG_DH_Share(y)$(YearVal(y) >= 2030) = 0.30;
WPG_DH_Share(y)$(YearVal(y) >= 2040) = 0.80;
WPG_DH_Share(y)$(YearVal(y) >= 2045) = 1;
parameter WPG_DH_Weight(t);
WPG_DH_Weight(t)$sum((r,m,y), OutputActivityRatio(r,t,'Heat_District',m,y)) = 1;
WPG_DH_Weight(t)$sum((r,m,y), InputActivityRatio(r,t,'Gas_Natural',m,y) + InputActivityRatio(r,t,'Hardcoal',m,y) + InputActivityRatio(r,t,'Lignite',m,y) + InputActivityRatio(r,t,'Oil',m,y)) = 0;
WPG_DH_Weight('CHP_WasteToEnergy') = 0.5;
equation DE_WPG_DistrictHeatRenewableShare(YEAR_FULL);
DE_WPG_DistrictHeatRenewableShare(y)$(WPG_DH_Share(y))..
  sum((t,r)$(not TagTechnologyToSubsets(t,'StorageDummies')), WPG_DH_Weight(t)*ProductionByTechnologyAnnual(y,t,'Heat_District',r)) =g= WPG_DH_Share(y)*sum((t,r)$(not TagTechnologyToSubsets(t,'StorageDummies')), ProductionByTechnologyAnnual(y,t,'Heat_District',r));

*##### Gebaeudeenergiegesetz par. 72 (4): no fossil fuels in building heating from 2045 #####
RateOfActivity.fx(y,l,t,m,r)$(TagTechnologyToSector(t,'Buildings') and not TagTechnologyToSubsets(t,'CHP') and YearVal(y) >= 2045
                              and (InputActivityRatio(r,t,'Gas_Natural',m,y) or InputActivityRatio(r,t,'Oil',m,y) or InputActivityRatio(r,t,'Hardcoal',m,y) or InputActivityRatio(r,t,'Lignite',m,y))) = 0;

*##### Growth limit of renewable building heat 3.3 % a year (assumption based on Gebaeudeenergiegesetz par. 72 (4)) #####
ProductionGrowthLimit('Heat_Buildings',y)$(YearVal(y) > 2025 and ProductionGrowthLimit('Heat_Buildings',y) < 0.033) = 0.033;

*##### Klimaschutzgesetz par. 3: national emission limit incl. exogenous emissions (2025: UBA emission data; 2035 interpolated) #####
AnnualEmissionLimit('CO2','2025') = 649;
AnnualEmissionLimit('CO2','2030') = 438;
AnnualEmissionLimit('CO2','2035') = 294;
AnnualEmissionLimit('CO2','2040') = 150;
AnnualEmissionLimit('CO2',y)$(YearVal(y) >= 2045) = 0;

*##### Klimaschutzgesetz par. 3 (2): negative emissions after 2050 (assumption based on the law) #####
AnnualEmissionLimit('CO2','2055') = -10;
AnnualEmissionLimit('CO2','2060') = -20;
$endif
