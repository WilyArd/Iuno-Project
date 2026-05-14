#!/usr/bin/env python3
import os
import sys
import subprocess
import argparse

def find_serial_ports():
    """Find available serial ports on Linux/Windows/Mac."""
    if sys.platform.startswith('win'):
        import serial.tools.list_ports
        ports = [port.device for port in serial.tools.list_ports.comports()]
    elif sys.platform.startswith('linux') or sys.platform.startswith('cygwin'):
        import glob
        ports = glob.glob('/dev/tty[A-Za-z]*')
    elif sys.platform.startswith('darwin'):
        import glob
        ports = glob.glob('/dev/tty.*')
    else:
        raise EnvironmentError('Unsupported platform')
    
    # Filter common ports
    filtered_ports = [p for p in ports if 'ttyUSB' in p or 'ttyACM' in p or 'COM' in p]
    return filtered_ports

def flash_device(port, baudrate, build_dir):
    """Flashes the ESP32 using esptool.py or idf.py."""
    if not os.path.exists(build_dir):
        print(f"Error: Build directory '{build_dir}' not found.")
        print("Please build the esp-claw project first.")
        return False
        
    print(f"Flashing device on port {port} at {baudrate} baud...")
    
    # Assuming esp-claw is built with ESP-IDF
    # The standard way to flash an ESP-IDF project is: idf.py -p PORT -b BAUD flash
    # Alternatively, you can use esptool.py directly if you know the bin locations.
    # We will use idf.py for simplicity as it handles partitions automatically.
    
    cmd = ["idf.py", "-p", port, "-b", str(baudrate), "flash"]
    
    try:
        # Run idf.py in the esp-claw directory
        process = subprocess.Popen(cmd, cwd=os.path.dirname(build_dir) or ".", stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        
        for line in process.stdout:
            print(line, end="")
            
        process.wait()
        
        if process.returncode == 0:
            print("\nFlashing completed successfully!")
            return True
        else:
            print(f"\nFlashing failed with exit code {process.returncode}")
            return False
            
    except FileNotFoundError:
        print("Error: 'idf.py' not found in PATH.")
        print("Please ensure ESP-IDF is installed and the export.sh script has been sourced.")
        print("Example: . $HOME/esp/esp-idf/export.sh")
        return False

def main():
    parser = argparse.ArgumentParser(description="IUNO ESP-Claw Flasher Utility")
    parser.add_argument("-p", "--port", help="Serial port (e.g., /dev/ttyUSB0, COM3)")
    parser.add_argument("-b", "--baud", type=int, default=460800, help="Baud rate (default: 460800)")
    parser.add_argument("-d", "--dir", default="../esp-claw/build", help="Path to esp-claw build directory (default: ../esp-claw/build)")
    
    args = parser.parse_args()
    
    port = args.port
    if not port:
        ports = find_serial_ports()
        if not ports:
            print("No serial ports found. Please specify one with -p or connect an ESP32.")
            sys.exit(1)
        elif len(ports) == 1:
            port = ports[0]
            print(f"Auto-detected serial port: {port}")
        else:
            print("Multiple serial ports found. Please specify one with -p:")
            for i, p in enumerate(ports):
                print(f"  {i+1}: {p}")
            choice = input("Select port (1-{}): ".format(len(ports)))
            try:
                port = ports[int(choice)-1]
            except (ValueError, IndexError):
                print("Invalid selection.")
                sys.exit(1)
                
    success = flash_device(port, args.baud, args.dir)
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()
