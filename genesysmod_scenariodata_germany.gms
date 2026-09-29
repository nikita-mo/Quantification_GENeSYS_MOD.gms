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

*##### Buildings renovation inertia (Moskalenko et al. 2026, Applied Energy 409, doi:10.1016/j.apenergy.2026.127508) #####
parameter Renovierungsrate(y_full);
Renovierungsrate(y) = 0.015;
Renovierungsrate(y)$(YearVal(y) > 2020) = 0.035;
Renovierungsrate(y)$(YearVal(y) > 2030) = 0.045;
Renovierungsrate(y)$(YearVal(y) > 2040) = 0.065;
equation BuildingsInertia(REGION_FULL,TECHNOLOGY,YEAR_FULL);
BuildingsInertia(r,t,y)$(TagTechnologyToSector(t,'Buildings') and YearVal(y) > 2015 and not TagTechnologyToSubsets(t,'CHP'))..
  ProductionByTechnologyAnnual(y,t,'Heat_Buildings',r) =g= (1 - sum(yy$(YearVal(yy) <= YearVal(y)), Renovierungsrate(yy)*YearlyDifferenceMultiplier(yy-1)))*ProductionByTechnologyAnnual('2018',t,'Heat_Buildings',r);

$ifthen %switch_de_policy% == 1
*##### NECP capacity floors on the national sum (EEG 2023 par. 4, WindSeeG par. 1) #####
TagRegionToSubsets(r,'DE_all') = 1;
TagTechnologyToSubsets(t,'NECP_Solar')$(TagTechnologyToSubsets(t,'Solar') and TagTechnologyToSubsets(t,'PowerSupply')) = 1;
TagTechnologyToSubsets(t,'NECP_Onshore')$(TagTechnologyToSubsets(t,'Onshore') and TagTechnologyToSubsets(t,'PowerSupply')) = 1;
TagTechnologyToSubsets(t,'NECP_Offshore')$(TagTechnologyToSubsets(t,'Offshore') and TagTechnologyToSubsets(t,'PowerSupply')) = 1;
option TechGroup < TagTechnologyToSubsets;
option RegionGroup < TagRegionToSubsets;
GroupTotalAnnualMinCapacity('NECP_Solar','DE_all','2025')    = 117.7;
GroupTotalAnnualMinCapacity('NECP_Solar','DE_all','2030')    = 215;
GroupTotalAnnualMinCapacity('NECP_Solar','DE_all','2035')    = 309;
GroupTotalAnnualMinCapacity('NECP_Solar','DE_all','2040')    = 400;
GroupTotalAnnualMinCapacity('NECP_Solar','DE_all',y)$(YearVal(y) > 2040)    = 400;
GroupTotalAnnualMinCapacity('NECP_Onshore','DE_all','2025')  = 64;
GroupTotalAnnualMinCapacity('NECP_Onshore','DE_all','2030')  = 115;
GroupTotalAnnualMinCapacity('NECP_Onshore','DE_all','2035')  = 157;
GroupTotalAnnualMinCapacity('NECP_Onshore','DE_all','2040')  = 160;
GroupTotalAnnualMinCapacity('NECP_Onshore','DE_all',y)$(YearVal(y) > 2040)  = 160;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_all','2025') = 9.215;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_all','2030') = 30;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_all','2035') = 40;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_all','2040') = 40;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_all','2045') = 70;
GroupTotalAnnualMinCapacity('NECP_Offshore','DE_all',y)$(YearVal(y) > 2045) = 70;

*##### Waermeplanungsgesetz par. 29-30: renewable and waste-heat share of district heating on the national sum #####
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

*##### Klimaschutzgesetz par. 3: national emission limit incl. exogenous emissions (2025: UBA emission data; 2035 interpolated) #####
AnnualEmissionLimit('CO2','2025') = 649;
AnnualEmissionLimit('CO2','2030') = 438;
AnnualEmissionLimit('CO2','2035') = 294;
AnnualEmissionLimit('CO2','2040') = 150;
AnnualEmissionLimit('CO2',y)$(YearVal(y) >= 2045) = 0;
$endif
