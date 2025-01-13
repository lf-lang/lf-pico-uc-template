# Template for the Lingua Franca RP2040 target platform
This is a project template for developing applications targeting the Raspberry Pi Pico using the micro-C target of Lingua Franca.


## Setup
Create a new repository based on this template, clone it recursively to your local machine and enter
the directory from your favourite shell.

Install a toolchain by following this instruction: https://www.lf-lang.org/embedded-lab/Non-Nix.html#install-cmake-standard-c-library-arm-cross-compiler

Install the picotool as describer here: https://www.lf-lang.org/embedded-lab/Non-Nix.html#install-picotool

Make sure that the `pico-sdk` submodule is initialized:

```sh
git submodule update --init --recursive
```

## Building
In this template we have integrated the Lingua Franca compiler `lfc` into the `CMake`. To build an application,
first configure the project using
```sh
cmake -Bbuild
```
This step will invoke `lfc` on the main LF application. 

Before compiling the application with

```sh
cmake --build build -j $(nproc)
```

To rebuild the application simply repeat the last command

```sh
cmake --build build -j $(nproc)
```

If CMake detects any changes to any files found in `src/*.lf` the configure step will be rerun.


## Flashing
Before flashing the binary to your rp2040 based board, the board must be placed into ``BOOTSEL`` mode. On a [Raspberry Pi Pico](https://www.raspberrypi.com/products/raspberry-pi-pico/) this can be entered by holding the ``RESET`` button while connecting the board to the host device. Run ``picotool help`` for more information on its
capabilities.

Run the following to flash an application binary on to your board.
``` shell
picotool load -x bin/Blink.elf
```

## Changing build parameters
To change build parameters, such as which LF application to build or the log level, we
recommend that you modify the corresponding variable at the top of the
[CMakeLists.txt](./CMakeLists.txt). Alternatively, you can override the variables from
the command line.
```sh
cmake -Bbuild -DLOG_LEVEL=LF_LOG_LEVEL_DEBUG .
```


### WSL
When using the Windows Subsystem for Linux on a windows machine for development, there are a few extra steps to attach the device to your wsl instance.
The official [instructions](https://learn.microsoft.com/en-us/windows/wsl/connect-usb) are reflected here. Install the required software and execute the following.

Open a powershell prompt as an administrator.
```
usbipd wsl list
```

Note the busid of either the RP2040 board or pico-probe that is trying to be mounted to the instance. These boards will likely show as either **USB Mass Storage Device, RP2 Boot** when connected in bootsel mode or 
as a **USB Serial Device** of some type when connected and hosting a USB stdio application.
Attach the device using the following command.
```
usbipd wsl attach --busid <bus_id>
```

This wil mount the device to the wsl instance while removing access to the device from the windows instance. In a wsl shell check the device has been attached.
After this is confirmed, copy the rp2040 udev rules and hotplug restart udev.
```
lsusb
wget https://raw.githubusercontent.com/raspberrypi/openocd/rp2040/contrib/60-openocd.rules -P /etc/udev/rules.d/
sudo service udev restart && sudo udevadm trigger
```

## Debugging
To debug applications for RP2040 based boards, there exists a nice tool called [picoprobe](https://github.com/raspberrypi/picoprobe). This applications allows a Raspberry Pi Pico or RP2040 board to act as a [cmsis-dap](https://arm-software.github.io/CMSIS_5/DAP/html/index.html) device which interacts with the target device cortex cores through a [serial wire debug](https://wiki.segger.com/SWD)(swd) pin interface connection.

To get started, you'll need a secondary RP2040 based board and will need to flash the picoprobe [binaries](https://github.com/raspberrypi/picoprobe/releases/tag/picoprobe-cmsis-v1.02)linked here. The page contains pre-built firmware packages that can be flashed using picotool or copied to a `bootsel` mounted board. 

### Wiring
Once the **probe** device is prepared, wire it up to the **target** device as follows. The following is an example of a pico to pico connection and the pin numbers will differ from board to board.

```
Probe GND -> Target GND
Probe GP2 -> Target SWCLK
Probe GP3 -> Target SWDIO
Probe GP4 (UART1 TX) -> Target GP1 (UART0 RX)
Probe GP5 (UART1 RX) -> Target GP0 (UART0 TX)
```

*UART0* is the default uart peripheral used for stdio when uart is enabled for stdio in cmake. The target board uart is passed through the probe and can be accessed as usual using a serial port communication program on the host device connected to the probe.

### OpenOCD
[Open On-Chip Debugger](https://openocd.org/) is a program that runs on host machines called a `debug translator` It understands the swd protocol and is able to communicate with the probe device while exposing a local debug server for `GDB` to attach to.

After wiring, run the following command to flash a test binary of your choice
```
openocd -f interface/cmsis-dap.cfg -c "adapter speed 5000" -f target/rp2040.cfg -c "program bin/HelloPico.elf verify reset exit"
```
The above will specify the 
- probe type: `cmsis-dap`
- the target type: `rp2040`
- commands: the `-c` flag will directly run open ocd commands used to configure the flash operation. 
	- `adapter speed 5000` makes the transaction faster
	- `program <binary>.elf` specifies the `elf` binary to load into flash memory. These binaries specify the areas of where different parts of the program are loaded and the sizes.
	- `verify` reads the flash and checks against the binary
	- `reset` places the mcu in a clean initial state
	- `exit` disconnects openocd and the program will start to run on the board

### GDB
The gnu debugger is an open source program for stepping through application code. Here we use the remote target feature to connect to the exposed debug server provided by openocd. 

Make sure the intended program to be debugged on the **target** device has an accessible `.elf` binary that was built using the `Debug` option. To specify this property in an LF program, add the following to the program header:

```lf
target uC {
    build-type: "Debug"
    ...
}
```

First start openocd using the following command

```bash
openocd -f interface/cmsis-dap.cfg -c "adapter speed 5000" -f target/rp2040.cfg -s tcl
```

In a separate terminal window, run the following GDB session providing the elf binary. Since this binary was built using the `Debug` directive, it will include a symbol table that will be used for setting up breakpoints in gdb.

```bash
gdb <binary>.elf
```
Once the GDB environment is opened, connect to the debug server using the following. Each core exposes its own port but `core0` which runs the main thread exposes `3333`.

```bash
(gdb) target extended-remote localhost:3333
```

From this point onwards normal gdb functionality such as breakpoints, stack traces and register analysis can be accessed through various gdb commands.