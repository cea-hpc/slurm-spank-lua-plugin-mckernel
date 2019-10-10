What is slurm-spank-lua-mckernel
===============================

McKernel is a light-weight multi-kernel operating system designed for high-end
supercomputing.

This plugin allow you to use Mckernel with Slurm resources manager.

More information:
* McKernel - https://www.sys.r-ccs.riken.jp/ResearchTopics/os/mckernel
* Slurm - https://slurm.schedmd.com
* Spank plugin - https://slurm.schedmd.com/spank.html
* Stanford spank-lua plugin - https://github.com/stanford-rc/slurm-spank-lua

Installation
===============

To use this plugin you have to install slurm and slurm-spank-lua plugin.

On CenOS/RHEL systems:

        yum install -y slurm slurm-spank-plugins-lua


Configure slurm to use spank lua plugin:

        cat /etc/slurm/plugstack.conf.d/lua-mixed.conf
            optional lua.so /etc/slurm/lua.d/*.lua


The plugin also need some additional dependencies:

        yum install -y hwloc clustershell


Now to use mckernel plugin, copy src/mckernel.lua and src/config.lua in the correct place

        cp src/mckernel.lua /etc/slurm/lua.d
        mkdir /etc/slurm/lua.d/mckernel
        cp src/config.lua /etc/slurm/lua.d/mckernel

You need to install this plugin on submission nodes and on compute resources where you want to use McKernel.

Install McKernel on the compute resources.

Documentation available here: https://github.com/RIKEN-SysSoft/mckernel



Configuration
================

You can configure the default resource alocated to the node by updating config.lua file.

Example:

        -- Use mckernel even if all cores are not allocated
        always_allow = true

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



Usage
=======

Once correctly installed, srun -h output should have theses new options:


      ...
      --enable_mckernel       Enable McKernel initialization (requires exclusive
                              allocation)

      --mck_memory=[amount@NUMA]
                              Reserve memory amount to McKernel (requires
                              exclusive allocation)

      --mck_cpus=[cpulist,...]
                              Reserve cpus to McKernel (requires exclusive
                              allocation)

      --mck_irqs=[MCKcpulist:cpulist+MCKcpulist:cpulist]
                              IRQs mapping between Linux cpus and McKernel
                              (requires exclusive allocation)
      ...

McKernel is now usable in slurm with this kind of commanline:

        srun --exclusive -p kbxi --enable_mckernel /opt/mckernel/bin/mcexec cat /proc/self/status

or (depending on you hardware):

        srun --exclusive -n1 -c 64 -p kbxi --enable_mckernel --mck_cpus=138-153,156-203,206-221,224-271 --mck_irqs=138:2+139:3+140:4+141:5+142:6+143:7+144:8+145:9+146:10+147:11+148:12+149:13+150:14+151:15+152:16+153:17+156:20+157:21+158:22+159:23+160:24+161:25+162:26+163:27+164:28+165:29+166:30+167:31+168:32+169:33+170:34+171:35+172:36+173:37+174:38+175:39+176:40+177:41+178:42+179:43+180:44+181:45+182:46+183:47+184:48+185:49+186:50+187:51+188:52+189:53+190:54+191:55+192:56+193:57+194:58+195:59+196:60+197:61+198:62+199:63+200:64+201:65+202:66+203:67+206:70+207:71+208:72+209:73+210:74+211:75+212:76+213:77+214:78+215:79+216:80+217:81+218:82+219:83+220:84+221:85+224:88+225:89+226:90+227:91+228:92+229:93+230:94+231:95+232:96+233:97+234:98+235:99+236:100+237:101+238:102+239:103+240:104+241:105+242:106+243:107+244:108+245:109+246:110+247:111+248:112+249:113+250:114+251:115+252:116+253:117+254:118+255:119+256:120+257:121+258:122+259:123+260:124+261:125+262:126+263:127+264:128+265:129+266:130+267:131+268:132+269:133+270:134+271:135 --mck_memory=12G@0,12G@1,12G@2,12G@3 /opt/mckernel/bin/mcexec numactl --hardware
