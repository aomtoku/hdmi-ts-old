
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name Gmii_receive -dir "/home/aom/Work/ver/Atlys/Gmii_receive/planAhead_run_4" -part xc6slx45csg324-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "/home/aom/Work/ver/Atlys/Gmii_receive/vtc_demo.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {/home/aom/Work/ver/Atlys/Gmii_receive} {core/fifo} {ipcore_dir} }
set_property target_constrs_file "/home/aom/Work/ver/Atlys/Gmii_receive/boards/atlys/synthesis/gmii_atlys.ucf" [current_fileset -constrset]
add_files [list {/home/aom/Work/ver/Atlys/Gmii_receive/boards/atlys/synthesis/gmii_atlys.ucf}] -fileset [get_property constrset [current_run]]
link_design
