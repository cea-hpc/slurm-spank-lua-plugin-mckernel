-- Minimum number of allocated cores on a single node to activate
-- Mckernel. Since we consider Mckernel can not be run by multiple
-- users on a single node, this parameter define if the node is exclusively
-- allocated. (0 deactivate McKernel plugin)
alloc_threshold = 64

-- Default configuration
default_settings = {
            -- Path of system tools (rmmod...)
            ["path"] = "/bin:/usr/bin:/sbin:/usr/sbin",
            -- By default, vm.legacy_va_layout must be isabled in McKernel.
            -- If you want to restore it after a run you can configure its value here.
            ["mck_legacy_va_layout"] = "1",
            -- McKernel installation path
            ["mck_path"] = "/opt/mckernel",
            -- Enable McKernel by default
            ["mck_enabled"] = "0",
            -- Default McKernel parameters (CPUs, Memory and IRQs)
            -- The value of each parameter must follow the mcreboot.sh syntax.
            ["mck_cpus"] = "1",
            ["mck_irqs"] = "",
            ["mck_memory"] = "20G"}
