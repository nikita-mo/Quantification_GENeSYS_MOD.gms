** Scenario data Germany, vertical-integration study: the 16 federal states in the German model, the node DE in the European model

$if not set switch_de_policy $setglobal switch_de_policy 0

*##### German regions: the federal states, or the node DE of the European model #####
* labels that one of the two models does not have in its data
set DE_Label / DE, DE_states, DE_NRW /;
set DE_Region(REGION_FULL);
DE_Region(r)$(TagRegionToSubsets(r,'DE_states') or sameas(r,'DE')) = yes;
scalar DE_national;
DE_national = 1$(card(DE_Region) = card(r));
abort$(not card(DE_Region)) "Scenario data Germany: no German region in the model.";
abort$(not DE_national and card(DE_Region) > 1) "Scenario data Germany: next to other countries Germany has to be one region.";
TagRegionToSubsets(DE_Region,'DE_states') = 1;
option RegionGroup < TagRegionToSubsets;
GroupTotalAnnualMaxCapacity(tg,'DE_states',y)$(not GroupTotalAnnualMaxCapacity(tg,'DE_states',y)) = 999999;

*##### Nuclear exit #####
TotalTechnologyAnnualActivityUpperLimit(DE_Region,'P_Nuclear',y)$(YearVal(y) >= 2025) = 0;
AvailabilityFactor(DE_Region,'P_Nuclear',y)$(YearVal(y) > 2020) = 0;

*##### Coal exit (Kohleverstromungsbeendigungsgesetz) #####
AvailabilityFactor(DE_Region,'P_Coal_Lignite',y)$(YearVal(y) > 2035) = 0;
AvailabilityFactor(DE_Region,'P_Coal_Lignite',y)$(sameas(DE_Region,'DE_NRW') and YearVal(y) > 2030) = 0;
AvailabilityFactor(DE_Region,'P_Coal_Hardcoal',y)$(YearVal(y) > 2035) = 0;
AvailabilityFactor(DE_Region,'CHP_Coal_Hardcoal',y)$(YearVal(y) > 2035) = 0;
AvailabilityFactor(DE_Region,'CHP_Coal_Lignite',y)$(YearVal(y) > 2035) = 0;
AvailabilityFactor(DE_Region,'CHP_Coal_Lignite',y)$(sameas(DE_Region,'DE_NRW') and YearVal(y) > 2030) = 0;
AvailabilityFactor(DE_Region,'R_Coal_Hardcoal',y)$(YearVal(y) > 2020) = 0;
ProductionByTechnologyAnnual.fx('2040',t,'Power',DE_Region)$(sum(m,InputActivityRatio(DE_Region,t,'Hardcoal',m,'2040'))) = 0;
ProductionByTechnologyAnnual.fx('2040',t,'Power',DE_Region)$(sum(m,InputActivityRatio(DE_Region,t,'Lignite',m,'2040'))) = 0;

*##### Buildings renovation inertia (assumption based on IWU 2018, Datenerhebung Wohngebaeudebestand 2016) #####
parameter Renovierungsrate(y_full);
Renovierungsrate(y) = 0.015;
Renovierungsrate(y)$(YearVal(y) > 2020) = 0.035;
Renovierungsrate(y)$(YearVal(y) > 2030) = 0.045;
Renovierungsrate(y)$(YearVal(y) > 2040) = 0.065;
equation BuildingsInertia(REGION_FULL,TECHNOLOGY,YEAR_FULL);
BuildingsInertia(r,t,y)$(DE_Region(r) and TagTechnologyToSector(t,'Buildings') and YearVal(y) > 2015 and not TagTechnologyToSubsets(t,'CHP') and AvailabilityFactor(r,t,y) >= AvailabilityFactor(r,t,'2018'))..
  ProductionByTechnologyAnnual(y,t,'Heat_Buildings',r) =g= (1 - sum(yy$(YearVal(yy) <= YearVal(y)), Renovierungsrate(yy)*YearlyDifferenceMultiplier(yy-1)))*ProductionByTechnologyAnnual('2018',t,'Heat_Buildings',r);

*##### National group caps (BECCS, biomass imports) on the sum of the 16 federal states; the node DE has them from the data #####
GroupTotalAnnualMaxCapacity(tg,'DE_states',y)$(DE_national and GroupTotalAnnualMaxCapacity(tg,'DE',y)) = GroupTotalAnnualMaxCapacity(tg,'DE',y);

*##### CCS only in high-temperature industry and BECCS #####
AvailabilityFactor(DE_Region,t,y)$(TagTechnologyToSubsets(t,'CCS')
                                   and not TagTechnologyToSubsets(t,'BECCS')
                                   and not (sameas(t,'HHI_BF_BOF_CCS') or sameas(t,'HHI_DRI_EAF_CCS'))) = 0;

*##### Fossil transport and gas-based steel in the phase-out smoothing; own equation where other countries are in the model #####
set DE_PhaseOut(TECHNOLOGY) / PSNG_Rail_Conv, FRT_Rail_Conv, FRT_Ship_Conv, PSNG_Air_Conv, HHI_DRI_EAF /;
TagTechnologyToSubsets(DE_PhaseOut,'PhaseOutSet')$DE_national = 1;
equation DE_SmoothingFossilPhaseOuts(YEAR_FULL,REGION_FULL,TECHNOLOGY,FUEL);
DE_SmoothingFossilPhaseOuts(y,DE_Region,DE_PhaseOut,f)$(not DE_national and YearVal(y) > %year% and SpecifiedAnnualDemand(DE_Region,f,y-1) and not RegionalBaseYearProduction(DE_Region,DE_PhaseOut,f,y))..
  ProductionByTechnologyAnnual(y,DE_PhaseOut,f,DE_Region) =l= ProductionByTechnologyAnnual(y-1,DE_PhaseOut,f,DE_Region)*PhaseOut(y)*((SpecifiedAnnualDemand(DE_Region,f,y)/SpecifiedAnnualDemand(DE_Region,f,y-1))$(SpecifiedAnnualDemand(DE_Region,f,y))+1$(not SpecifiedAnnualDemand(DE_Region,f,y)));

*##### 2025 as historic year: no power from technologies without production statistics #####
ProductionByTechnologyAnnual.fx('2025',t,'Power',DE_Region)$((TagTechnologyToSubsets(t,'PowerSupply') or TagTechnologyToSubsets(t,'CHP') or sameas(t,'CHP_WasteToEnergy')) and not RegionalBaseYearProduction(DE_Region,t,'Power','2025')
                                                             and sum(TECHNOLOGY, RegionalBaseYearProduction(DE_Region,TECHNOLOGY,'Power','2025'))) = 0;

*##### 2025 as historic year: no new hydrogen road vehicles #####
NewCapacity.fx('2025',t,DE_Region)$(sameas(t,'PSNG_Road_H2') or sameas(t,'FRT_Road_H2')) = 0;

*##### Emissions per sector and region are not allowed to increase; negative-emission technologies are not counted #####
parameter DE_NegativeEmission(TECHNOLOGY);
DE_NegativeEmission(t)$(smin((DE_Region,m,e,y), EmissionActivityRatio(DE_Region,t,m,e,y)) < 0) = 1;
equation E13a_SectoralEmissionReduction(y_full,EMISSION,SECTOR,REGION_FULL);
E13a_SectoralEmissionReduction(y,e,se,r)$(DE_Region(r) and YearVal(y) > %year% and not sum((t,f), RegionalBaseYearProduction(r,t,f,y)))..
  sum(t$(TagTechnologyToSector(t,se) and not DE_NegativeEmission(t)), AnnualTechnologyEmission(y,t,e,r)) =l= sum(t$(TagTechnologyToSector(t,se) and not DE_NegativeEmission(t)), AnnualTechnologyEmission(y-1,t,e,r));

$ifthen %switch_de_policy% == 1
*##### NECP capacity floors on the national sum (EEG 2023 par. 4, WindSeeG par. 1) #####
TagTechnologyToSubsets(t,'NECP_Solar')$(TagTechnologyToSubsets(t,'Solar') and TagTechnologyToSubsets(t,'PowerSupply')) = 1;
TagTechnologyToSubsets(t,'NECP_Onshore')$(TagTechnologyToSubsets(t,'Onshore') and TagTechnologyToSubsets(t,'PowerSupply')) = 1;
TagTechnologyToSubsets(t,'NECP_Offshore')$(TagTechnologyToSubsets(t,'Offshore') and TagTechnologyToSubsets(t,'PowerSupply')) = 1;
TagTechnologyToSubsets('X_Electrolysis','NWS_Electrolysis') = 1;
TagTechnologyToSubsets('D_Battery_Li-Ion','NEP_Battery') = 1;
TagTechnologyToSubsets('D_Battery_Redox','NEP_Battery') = 1;
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

*##### Large battery storage on the national sum: path of the NEP scenario framework 2025, scenario B (assumption based on the Szenariorahmen 2037/2045; 2025 from the data) #####
GroupTotalAnnualMinCapacity('NEP_Battery','DE_states','2030') = 29.6;
GroupTotalAnnualMinCapacity('NEP_Battery','DE_states','2035') = 56.7;
GroupTotalAnnualMinCapacity('NEP_Battery','DE_states',y)$(YearVal(y) >= 2040) = 67.6;

*##### Nationale Wasserstoffstrategie 2023: 10 GW of electrolysis (electric input) from 2030 on the national sum #####
GroupTotalAnnualMinCapacity('NWS_Electrolysis','DE_states',y)$(YearVal(y) >= 2030) = 10/smax(DE_Region, InputActivityRatio(DE_Region,'X_Electrolysis','Power','1','2030'));

*##### Waermeplanungsgesetz par. 29-31: renewable and waste-heat share of district heating on the national sum, fully from 2045 #####
parameter WPG_DH_Share(y_full);
WPG_DH_Share(y)$(YearVal(y) >= 2030) = 0.30;
WPG_DH_Share(y)$(YearVal(y) >= 2040) = 0.80;
WPG_DH_Share(y)$(YearVal(y) >= 2045) = 1;
parameter WPG_DH_Weight(t);
WPG_DH_Weight(t)$sum((DE_Region,m,y), OutputActivityRatio(DE_Region,t,'Heat_District',m,y)) = 1;
WPG_DH_Weight(t)$sum((DE_Region,m,y), InputActivityRatio(DE_Region,t,'Gas_Natural',m,y) + InputActivityRatio(DE_Region,t,'Hardcoal',m,y) + InputActivityRatio(DE_Region,t,'Lignite',m,y) + InputActivityRatio(DE_Region,t,'Oil',m,y)) = 0;
WPG_DH_Weight('CHP_WasteToEnergy') = 0.5;
equation DE_WPG_DistrictHeatRenewableShare(YEAR_FULL);
DE_WPG_DistrictHeatRenewableShare(y)$(WPG_DH_Share(y))..
  sum((t,DE_Region)$(not TagTechnologyToSubsets(t,'StorageDummies')), WPG_DH_Weight(t)*ProductionByTechnologyAnnual(y,t,'Heat_District',DE_Region)) =g= WPG_DH_Share(y)*sum((t,DE_Region)$(not TagTechnologyToSubsets(t,'StorageDummies')), ProductionByTechnologyAnnual(y,t,'Heat_District',DE_Region));

*##### Gebaeudeenergiegesetz par. 72 (4): no fossil fuels in building heating from 2045 #####
RateOfActivity.fx(y,l,t,m,DE_Region)$(TagTechnologyToSector(t,'Buildings') and not TagTechnologyToSubsets(t,'CHP') and YearVal(y) >= 2045
                                      and (InputActivityRatio(DE_Region,t,'Gas_Natural',m,y) or InputActivityRatio(DE_Region,t,'Oil',m,y) or InputActivityRatio(DE_Region,t,'Hardcoal',m,y) or InputActivityRatio(DE_Region,t,'Lignite',m,y))) = 0;

*##### No fossil fuels in power and CHP plants from 2045 (assumption based on EEG and Klimaschutzgesetz) #####
RateOfActivity.fx(y,l,t,m,DE_Region)$(YearVal(y) >= 2045 and OutputActivityRatio(DE_Region,t,'Power',m,y)
                                      and (InputActivityRatio(DE_Region,t,'Gas_Natural',m,y) or InputActivityRatio(DE_Region,t,'Oil',m,y) or InputActivityRatio(DE_Region,t,'Hardcoal',m,y) or InputActivityRatio(DE_Region,t,'Lignite',m,y))) = 0;

*##### Output of technologies that use hard coal does not grow after 2045 on the national sum (assumption based on Klimaschutzgesetz) #####
equation DE_HardcoalNoGrowth(YEAR_FULL,TECHNOLOGY);
DE_HardcoalNoGrowth(y,t)$(YearVal(y) > 2045 and sum((DE_Region,m), InputActivityRatio(DE_Region,t,'Hardcoal',m,y)))..
  sum((f,DE_Region), ProductionByTechnologyAnnual(y,t,f,DE_Region)) =l= sum((f,DE_Region), ProductionByTechnologyAnnual(y-1,t,f,DE_Region));

*##### Growth limit of renewable building heat 3.3 % a year (assumption based on Gebaeudeenergiegesetz par. 72 (4)); the limit has no region, it holds for every region of the model #####
ProductionGrowthLimit('Heat_Buildings',y)$(YearVal(y) > 2025 and ProductionGrowthLimit('Heat_Buildings',y) < 0.033) = 0.033;

*##### Klimaschutzgesetz par. 3: national emission limit incl. exogenous emissions (2025: UBA emission data; 2035 interpolated) #####
*##### Klimaschutzgesetz par. 3 (2): negative emissions after 2050 (assumption based on the law) #####
parameter DE_EmissionLimit(y_full);
DE_EmissionLimit('2025') = 649;
DE_EmissionLimit('2030') = 438;
DE_EmissionLimit('2035') = 294;
DE_EmissionLimit('2040') = 150;
DE_EmissionLimit(y)$(YearVal(y) >= 2045) = 0;
DE_EmissionLimit('2055') = -10;
DE_EmissionLimit('2060') = -20;
AnnualEmissionLimit('CO2',y)$(DE_national and YearVal(y) >= 2025) = DE_EmissionLimit(y);
RegionalAnnualEmissionLimit(DE_Region,'CO2',y)$(not DE_national and YearVal(y) >= 2025) = DE_EmissionLimit(y);
$endif

*##### Rules of the European scenario file (genesysmod_scenariodata_europe.gms); the stop of new power capacity in 2025 counts the floors above #####
ProductionByTechnologyAnnual.up(y,'HD_Heatpump_ExcessHeat','Heat_District',DE_Region)$(YearVal(y) > 2018) = DistrictHeatDemand(DE_Region,y)*0.08;
ProductionByTechnologyAnnual.up(y,'HLI_Geothermal','Heat_Low_Industrial',DE_Region) = SpecifiedAnnualDemand(DE_Region,'Heat_Low_Industrial',y)*0.25;
ProductionByTechnologyAnnual.up(y,'CHP_WasteToEnergy','Heat_District',DE_Region) = RegionalBaseYearProduction(DE_Region,'CHP_WasteToEnergy','Heat_District','2018');
ProductionByTechnologyAnnual.lo('2025','HB_Oil_Boiler','Heat_Buildings',DE_Region) = RegionalBaseYearProduction(DE_Region,'HB_Oil_Boiler','Heat_Buildings','2018')*0.3;
CurtailmentCostFactor = 0.1;
NewCapacity.up('2025',t,DE_Region)$TagTechnologyToSubsets(t,'PowerSupply') = +INF;
NewCapacity.up('2025',t,DE_Region)$(TagTechnologyToSubsets(t,'PowerSupply') and not AnnualMinNewCapacity(DE_Region,t,'2025') and not TotalAnnualMinCapacity(DE_Region,t,'2025')
                                    and not sum((tg,rg)$(TagTechnologyToSubsets(t,tg) and TagRegionToSubsets(DE_Region,rg)), GroupTotalAnnualMinCapacity(tg,rg,'2025'))) = 0;

*##### Finite bounds on the emission accounting variables, without them the barrier solver misses the emission limits #####
AnnualEmissions.lo(y,e,DE_Region) = -5000;
AnnualEmissions.up(y,e,DE_Region) = 5000;
AnnualTechnologyEmission.lo(y,t,e,DE_Region) = -1000;
AnnualTechnologyEmission.up(y,t,e,DE_Region) = 1000;
AnnualTechnologyEmissionByMode.lo(y,t,e,m,DE_Region) = -1000;
AnnualTechnologyEmissionByMode.up(y,t,e,m,DE_Region) = 1000;

*##### Go RES without the policy block, German model: German part of the European 1.5 degree carbon budget 2018-2060 (assumption based on the European Go RES run) #####
$if %emissionPathway%%switch_de_policy% == Green0 ModelPeriodEmissionLimit('CO2')$DE_national = 6944;
