*
* ############ Vertical-integration study: European runs ############
*
* The European model of the study: the Man0EUvRE scenario for every country and, for the node DE, the rules of the
* German model from the same scenario file. Loaded with --project_scenario=vertical_integration instead of man0euvre.
*
$if not %model_region% == europe $abort "project_scenario vertical_integration is for the European model (model_region europe)"

*##### Rules of the German model for the node DE #####
$include genesysmod_scenariodata_germany.gms

*##### Man0EUvRE for every country; for DE the German model's road modal split and scrap-EAF bound stay #####
parameter VI_ModalSplitDE(FUEL,MODALTYPE,YEAR_FULL);
parameter VI_ScrapEAFUpDE(YEAR_FULL);
VI_ModalSplitDE(f,mt,y) = ModalSplitByFuelAndModalType('DE',f,mt,y);
VI_ScrapEAFUpDE(y) = ProductionByTechnologyAnnual.up(y,'HHI_Scrap_EAF','Heat_High_Industrial','DE');

$include %projectdir%genesysmod_scenariodata_man0euvre.gms

ModalSplitByFuelAndModalType('DE',f,mt,y) = VI_ModalSplitDE(f,mt,y);
ProductionByTechnologyAnnual.up(y,'HHI_Scrap_EAF','Heat_High_Industrial','DE') = VI_ScrapEAFUpDE(y);

*##### NECP Essentials: Germany's capacity targets are lower bounds in the German scenario file, not the exact values of Man0EUvRE #####
$ifthen %emissionPathway% == NECPEssentials
NECPCapacityPlans('DE',subset,y) = 0;
$endif
