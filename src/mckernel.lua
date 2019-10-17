
_posix = require "posix"

-- Allocation threshold (number of allocated cores) needed to activate Mckernel
-- plugin.
alloc_threshold = 1

dofile("/etc/slurm/lua.d/mckernel/config.lua")

-- Set logging primitives
local debug = SPANK.log_debug
local verbose = SPANK.log_verbose
local error = SPANK.log_error

local path = default_settings["path"]
local mck_enabled = default_settings["mck"]
local mck_memory = default_settings["mck_memory"]
local mck_cpus = default_settings["mck_cpus"]
local mck_irqs = default_settings["mck_irqs"]
local mck_path = default_settings["mck_path"]
local mck_user
local setting_requested = 0
-- Backup current node settings
local legacy_va_layout = default_settings["mck_legacy_va_layout"]


-- Helper function to set environment variables
function setenv(env_name, val)
   local r, msg = _posix.setenv(env_name, val)
   if r ~= 0 then
      SPANK.log_error("Failed to set variable %s: %s", env_name, val)
      return 1
   end
   return 0
end

-- Helper function to log external commands
function do_and_log_output (cmd)

   verbose("lua/mckernel: setting path to %s", path)
   setenv("PATH", path)
   verbose("lua/mckernel: executing %s", cmd)
   local f = io.popen(cmd.." 2>&1")
   local ret = true

   if not f then
       return false
   end

   for line in f:lines()
   do
      verbose("lua/mckernel: %s",line)
   end
   f:close()

   return ret
end

-- Helper function to process outputs from external commands
function do_and_return_output (cmd)

   verbose("lua/mckernel: setting path to %s", path)
   setenv("PATH", path)
   verbose("lua/mckernel: executing %s", cmd)
   local f = assert(io.popen(cmd.." 2>&1"))
   local s = assert(f:read('*a'))

   return s
end
-- Find if a allocated node is fully allocated (exclusive mode)
function is_exclusive(allocated_nodes)
    return allocated_nodes >= alloc_threshold
end

--
-- McKernel initialisation
function init_mckernel (memory, cpus, irqs)
    local cmdline = mck_path.."/sbin/mcreboot.sh -m "..memory.." -c "..cpus.." -o "..mck_user
    if irqs and irqs ~= "" then
        cmdline = cmdline .. " -r ".. irqs
    end
    -- This setting is needed for McKernel to work
    do_and_log_output("sysctl -w vm.legacy_va_layout=0")
    --
    return do_and_log_output(cmdline)
end

function deinit_mckernel ()
    do_and_log_output(mck_path.."/sbin/mcstop+release.sh")
    do_and_log_output("/sbin/sysctl -w vm.legacy_va_layout="..tostring(legacy_va_layout))
end


-- Callback to set global vars if the plugin is enabled
function opt_handler (val, arg, remote)
   setting_requested = 1
   if val == 1 then
     mck_enabled = 1
   elseif val == 2 then
     mck_memory = arg
   elseif val == 3 then
     mck_cpus = arg
   elseif val == 4 then
     mck_irqs = arg
   end
end


-- Init for all contexts
function slurm_spank_init(spank)
   -- register our option
   mck_spank_opt =  {
      name = "enable_mckernel",
      usage = "Enable McKernel initialization (requires exclusive allocation)",
      cb = "opt_handler",
      val = 1,
      has_arg = 0
   }

   mck_mem_spank_opt =  {
      name = "mck_memory",
      usage = "Reserve memory amount to McKernel (requires exclusive allocation)",
      cb = "opt_handler",
      val = 2,
      has_arg = 1,
      arginfo = "[amount@NUMA]"
   }

   mck_cpu_spank_opt =  {
      name = "mck_cpus",
      usage = "Reserve cpus to McKernel (requires exclusive allocation)",
      cb = "opt_handler",
      val = 3,
      has_arg = 1,
      arginfo = "[cpulist,...]"
   }

   mck_irqs_spank_opt =  {
      name = "mck_irqs",
      usage = "IRQs mapping between Linux cpus and McKernel (requires exclusive allocation)",
      cb = "opt_handler",
      val = 4,
      has_arg = 1,
      arginfo = "[MCKcpulist:cpulist+MCKcpulist:cpulist]"
   }

   spank:register_option(mck_spank_opt)
   spank:register_option(mck_mem_spank_opt)
   spank:register_option(mck_cpu_spank_opt)
   spank:register_option(mck_irqs_spank_opt)

   return SPANK.SUCCESS
end

-- Called after options have been processed
function slurm_spank_init_post_opt (spank)

    if not mck_enabled then
        return SPANK.SUCCESS
    end
    mck_user = spank:get_item("S_JOB_UID")

    if (setting_requested and spank.context == "remote") then
      verbose("lua/mckernel: init_post_op: user requested a privileged setting")
      local job_alloc_cores = spank:get_item("S_JOB_ALLOC_CORES")
      verbose("lua/mckernel: job_alloc_cores: "..job_alloc_cores)
      local job_num_cores=tonumber(do_and_return_output("/usr/bin/nodeset -R -c "..job_alloc_cores))
      verbose("lua/mckernel: job_num_cores: "..job_num_cores)

      if job_num_cores and is_exclusive(job_num_cores) then
         if init_mckernel(mck_memory, mck_cpus, mck_irqs) then
            return SPANK.SUCCESS
         end
         return -1
      else
         verbose("lua/mckernel: init_post_op: cannot set a privileged setting without owning all cores")
         return -1
      end
    end

    return SPANK.SUCCESS
end

-- Called at job prolog
function slurm_spank_job_prolog (spank)
    return SPANK.SUCCESS
end

-- Called at job epilog
function slurm_spank_job_epilog (spank)
    verbose("lua/mckernel: epilog: shutting down mckernel")
    deinit_mckernel()
    return SPANK.SUCCESS
end
