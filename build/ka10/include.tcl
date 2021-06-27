#Default ITS name for KA10.
set mchn "KA"

set cpu "ka10"
set salv "salv"

proc start_dskdmp_its {} {
    start_dskdmp build/pdp10-ka/boot

    respond "DSKDMP" "its\r"
    patch_its_and_go
}

proc mark_pack {unit pack id} {
    respond "\n" "mark\033g"
    respond "UNIT #" "$unit"
    respond "#$unit?" "y"
    respond "NO =" "$pack\r"
    expect -timeout 300 "VERIFICATION"
    respond "ALLOC =" "3000\r"
    respond "PACK ID =" "$id\r"
}

proc mark_packs {} {
    mark_pack "0" "2" "2"
    mark_pack "1" "3" "3"
    mark_pack "2" "0" "0"
    mark_pack "3" "1" "1"
}

proc prepare_frontend {} {
}

proc frontend_bootstrap {} {
}

proc its_switches {} {
    global mchn
    respond "MACHINE NAME =" "$mchn\r"
}

proc make_ntsddt {} {
    respond "*" ":midas dsk0:.;@ ddt_system;ddt\r"
    respond "cpusw=" "0\r"
    respond "ndsk=" "0\r"
    respond "dsksw=" "0\r"
    respond "dsktp=" "0\r"
    respond "1PRSW=" "1\r"
    expect ":KILL"

    # Old NTS DDT with 340 support.
    respond "*" ":midas dsk0:.;@ ntsddt_syseng; ntsddt\r"
    expect ":KILL"
}

proc make_salv {} {
    global mchn

    respond "*" ":midas dsk0:.;_system;salv\r"
    respond "time-sharing?" "n\r"
    respond "machine?" "$mchn\r"
    expect ":KILL"
}

proc dskdmp_switches {hriflg} {
    expect "Configuration"
    respond "?" "ASK\r"
    respond "HRIFLG=" "$hriflg\r"
    respond "BOOTSW=" "N\r"
    respond "R11R6P=" "N\r"
    respond "R11R7P=" "N\r"
    respond "RM03P=" "N\r"
    respond "RM80P=" "N\r"
    respond "RH10P=" "N\r"
    respond "DC10P=" "N\r"
    respond "NUDSL=" "250.\r"
    respond "KS10P=" "N\r"
    respond "KL10P=" "N\r"
}

proc make_dskdmp {} {
    global emulator_escape
    global out

    respond "*" ":midas dsk0:.;@ dskdmp_system;dskdmp\r"
    dskdmp_switches "N"
    expect ":KILL"
}

proc dump_switches {} {
    global mchn

    respond "WHICH MACHINE?" "$mchn\r"
}

proc peek_switches {} {
    respond "with ^C" "340P==1\r\003"
}

proc dump_nits {} {
    global salv

    # Run the new DSKDMP from disk here, to check that it works.
    respond "DSKDMP" "dskdmp\r"

    respond "DSKDMP" "l\033ddt\r"

    # Dump an executable @ SALV.
    respond "\n" "t\033$salv bin\r"
    respond "\n" "\033u"
    respond "DSKDMP" "d\033$salv\r"

    # Since we bootstrap with a 2-pack ITS, we need to copy the MFD to
    # the fresh packs.
    respond "\n" "$salv\r"
    respond "\n" "ucop\033g"
    respond "UNIT #" "0"
    respond "UNIT #" "2"
    respond "OK?" "Y"
    respond "DDT" "ucop\033g"
    respond "UNIT #" "0"
    respond "UNIT #" "3"
    respond "OK?" "Y"
    respond "DDT" "\033u"

    # Now dump the new ITS.
    respond "DSKDMP" "t\033its bin\r"
    respond "\n" "\033u"
    respond "DSKDMP" "m\033$salv bin\r"
    respond "\n" "d\033nits\r"
    respond "\n" "g\033"
}

proc magdmp_switches {} {
    respond "KL10P=" "n\r"
    respond "TM10BP=" "n\r"
    # 340P=y doesn't work yet.
    respond "340P=" "n\r"
}

proc bootable_tapes {} {
    global emulator_escape
    global out
    global mchn

    respond "*" ":midas .;magdmp bin.${mchn}_syseng;magdmp\r"
    respond "PTRHRI=" "n\r"
    magdmp_switches
    expect ":KILL"

    respond "*" $emulator_escape
    create_tape "$out/magdmp.tape"

    type ":magfrm\r"
    respond "?" "$mchn\r"
    respond "?" "Y"
    respond "_" "W"
    respond "FROM" ".; @ DDT\r"
    respond "FILE" "@ DDT\r"
    respond "_" "W"
    respond "FROM" ".; @ SALV\r"
    respond "FILE" "@ SALV\r"
    respond "_" "W"
    respond "FROM" ".; @ DSKDMP\r"
    respond "FILE" "@ DSKDMP\r"
    respond "_" "Q"
    expect ":KILL"
}

proc update_microcode {} {
}

proc clib_switches {} {
    respond "with ^C" "\003"
}

proc translate_diagnostics {} {
    respond "*" "\033\024"
    respond " " "dsk: maint; part f, part f.old\r"
    respond "*" "\033\024"
    respond " " "dsk: maint; part g, part g.old\r"
    respond "*" "\033\024"
    respond " " "dsk: maint; part k, part k.old\r"
}

proc patch_clib_16 {} {
    respond "*" ":job clib\r"
    respond "*" "\033\060l"
    respond " " "c; \[clib\] 16\r"
    respond "*" "23237/"
    respond "FIX" "ufa 1,775763\n"
    respond "JRST" "tlo 2,777000\r"
    respond "\n" "23244/"
    respond "FIX" "ufa 1,775763\n"
    respond "MOVN" "tlo 2,777000\n"
    respond "JRST" "movn 2,2\r"
    respond "\n" "\033\060y"
    respond " " "c; \[clib\] 16\r"
    respond "*" ":kill\r"
}

proc copy_to_klfe {file} {
}

proc comsat_switches {} {
    respond "Limit to KA-10 instructions" "y\r"
}

proc dqxdev_switches {} {
    respond "Limit to KA-10 instructions" "y\r"
}

proc processor_basics {} {
}
