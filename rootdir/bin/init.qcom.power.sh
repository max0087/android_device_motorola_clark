#!/system/bin/sh

################################################################################
# helper functions to allow Android init like script

function write() {
    echo -n $2 > $1
}

function copy() {
    cat $1 > $2
}

function get-set-forall() {
    for f in $1 ; do
        cat $f
        write $f $2
    done
}

################################################################################

# take the A57s offline when thermal hotplug is disabled
write /sys/devices/system/cpu/cpu4/online 0
write /sys/devices/system/cpu/cpu5/online 0

# disable thermal bcl hotplug to switch governor
write /sys/module/msm_thermal/core_control/enabled 0
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode disable
bcl_hotplug_mask=`get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_mask 0`
bcl_hotplug_soc_mask=`get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask 0`
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode enable

# some files in /sys/devices/system/cpu are created after the restorecon of
# /sys/. These files receive the default label "sysfs".
# Restorecon again to give new files the correct label.
restorecon -R /sys/devices/system/cpu

# Disable CPU retention
write /sys/module/lpm_levels/system/a53/cpu0/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a53/cpu1/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a53/cpu2/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a53/cpu3/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a57/cpu4/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a57/cpu5/retention/idle_enabled 0

# Disable L2 retention
write /sys/module/lpm_levels/system/a53/a53-l2-retention/idle_enabled 0
write /sys/module/lpm_levels/system/a57/a57-l2-retention/idle_enabled 0

# Setup Little interactive settings
write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor interactive
restorecon -R /sys/devices/system/cpu # must restore after interactive
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load 1
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif 1
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay 19000
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load 95
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate 19000
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq 960000
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy 1
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads "65 460800:75 960000:80"
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time 39000
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis 79000
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/ignore_hispeed_on_notif 1
write /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 384000

# Make sure CPU 4 is only to configure big settings
write /sys/devices/system/cpu/cpu4/online 1
restorecon -R /sys/devices/system/cpu # must restore after online

# Setup Big interactive settings
write /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor interactive
restorecon -R /sys/devices/system/cpu # must restore after interactive
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_sched_load 1
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_migration_notif 1
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay 19000
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load 99
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate 19000
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq 1248000
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy 1
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads "70 960000:80 1248000:85"
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time 39000
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis 79000
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/ignore_hispeed_on_notif 1
write /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq 384000

# Configure core_ctl
write /sys/devices/system/cpu/cpu4/core_ctl/max_cpus 2
write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 1
write /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres 60
write /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres 30
write /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms 100
write /sys/devices/system/cpu/cpu4/core_ctl/is_big_cluster 1
write /sys/devices/system/cpu/cpu4/core_ctl/task_thres 4

# Available Freqs in stock kernel
# Little: 384000 460800 600000 672000 787200 864000 960000 1248000 1440000
# Big: 384000 480000 633600 768000 864000 960000 1248000 1344000 1440000 1536000 1632000 1689600 1824000
write /sys/module/cpu_boost/parameters/boost_ms 20
write /sys/module/cpu_boost/parameters/sync_threshold 960000
write /sys/module/cpu_boost/parameters/input_boost_freq 0:787200
write /sys/module/cpu_boost/parameters/input_boost_ms 40

# b.L scheduler parameters
write /proc/sys/kernel/sched_migration_fixup 1
write /proc/sys/kernel/sched_small_task 30
write /proc/sys/kernel/sched_mostly_idle_load 20
write /proc/sys/kernel/sched_mostly_idle_nr_run 3
write /proc/sys/kernel/sched_downmigrate 50
write /proc/sys/kernel/sched_upmigrate 70
write /proc/sys/kernel/sched_init_task_load 50
write /proc/sys/kernel/sched_freq_inc_notify 400000
write /proc/sys/kernel/sched_freq_dec_notify 400000

# enable rps static configuration
write /sys/class/net/rmnet_ipa0/queues/rx-0/rps_cpus 8

# devfreq
get-set-forall /sys/class/devfreq/qcom,cpubw*/governor bw_hwmon
restorecon -R /sys/class/devfreq/qcom,cpubw*
get-set-forall /sys/class/devfreq/qcom,mincpubw*/governor cpufreq

# Disable sched_boost
write /proc/sys/kernel/sched_boost 0

# set GPU default power level to 5 (180MHz) instead of 4 (305MHz)
write /sys/class/kgsl/kgsl-3d0/default_pwrlevel 5

# Configure foreground and background cpuset
write /dev/cpuset/foreground/cpus 0-5
write /dev/cpuset/foreground/boost/cpus 4-5
write /dev/cpuset/background/cpus 0-2
write /dev/cpuset/system-background/cpus 0-3

# android background processes are set to nice 10. Never schedule these on the a57s.
write /proc/sys/kernel/sched_upmigrate_min_nice 9

# set GPU default governor to msm-adreno-tz
write /sys/class/devfreq/fdb00000.qcom,kgsl-3d0/governor msm-adreno-tz

# re-enable thermal and BCL hotplug
write /sys/module/msm_thermal/core_control/enabled 1
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode disable
get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_mask $bcl_hotplug_mask
get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask $bcl_hotplug_soc_mask
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode enable

# allow CPUs to go in deeper idle state than C0
write /sys/module/lpm_levels/parameters/sleep_disabled 0
