import tkinter as tk
from tkinter import ttk
import yaml
import subprocess
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

GENERATOR_SCRIPT = os.path.join(SCRIPT_DIR, "generator.py")
INPUT_FILE = os.path.join(SCRIPT_DIR, "input.yaml")
RESULT_DIR = os.path.join(SCRIPT_DIR, "results")


# -----------------------------
# Write YAML file
# -----------------------------
def write_yaml(cfg):

    with open(INPUT_FILE, "w") as f:
        yaml.dump(cfg, f)


# -----------------------------
# Placeholder Entry
# -----------------------------
class PlaceholderEntry(tk.Entry):

    def __init__(self, master=None, placeholder="", color='grey'):
        super().__init__(master)

        self.placeholder = placeholder
        self.placeholder_color = color
        self.default_fg_color = self['fg']

        self.put_placeholder()

        self.bind("<FocusIn>", self.foc_in)
        self.bind("<FocusOut>", self.foc_out)

    def put_placeholder(self):

        self.insert(0, self.placeholder)
        self['fg'] = self.placeholder_color

    def foc_in(self, *args):

        if self['fg'] == self.placeholder_color:
            self.delete('0', 'end')
            self['fg'] = self.default_fg_color

    def foc_out(self, *args):

        if not self.get():
            self.put_placeholder()

    def get_value(self):

        if self['fg'] == self.placeholder_color:
            return ""
        return self.get()


# -----------------------------
# Run generator
# -----------------------------
def run_generator():

    cfg = {
        "memory_size": int(memory_size.get_value()),
        "data_width": int(data_width.get_value()),
        "num_ports": int(num_ports.get_value()),
        "read_ports": int(read_ports.get_value()),
        "write_ports": int(write_ports.get_value()),
        "num_banks": int(num_banks.get_value()),
        "clock_frequency": int(clock_frequency.get_value()),
        "priority": priority.get(),
        "access_pattern": access_pattern.get(),
        "N": int(N.get_value())
    }

    write_yaml(cfg)

    subprocess.run(["python", GENERATOR_SCRIPT])

    arch_dirs = [
        d for d in os.listdir(RESULT_DIR)
        if os.path.isdir(os.path.join(RESULT_DIR, d))
    ]

    if not arch_dirs:
        print("No architecture folder found")
        return

    arch = max(
        arch_dirs,
        key=lambda d: os.path.getmtime(os.path.join(RESULT_DIR, d))
    )

    run_simulation(arch)


# -----------------------------
# Run simulation
# -----------------------------
def run_simulation(arch):

    tb_dir = os.path.join(RESULT_DIR, arch, "tb")

    if not os.path.exists(tb_dir):
        print("TB folder not found")
        return

    cmd_compile = "vlog -sv ../rtl/*.v *.v"
    cmd_sim = f'vsim -c {arch}_memory_tb -do "run -all; quit"'

    subprocess.run(cmd_compile, cwd=tb_dir, shell=True)
    subprocess.run(cmd_sim, cwd=tb_dir, shell=True)

    display_reports(arch)


# -----------------------------
# Display reports
# -----------------------------
def display_reports(arch):

    report_dir = os.path.join(RESULT_DIR, arch, "reports")

    perf_file = os.path.join(report_dir, "performance_report.txt")
    arch_file = os.path.join(report_dir, "architecture_report.txt")

    report_box.delete("1.0", tk.END)

    report_box.insert(tk.END, "SELECTED ARCHITECTURE\n")
    report_box.insert(tk.END, "=====================\n\n")
    report_box.insert(tk.END, f"{arch.upper()}\n\n")

    if os.path.exists(arch_file):

        with open(arch_file) as f:
            lines = f.readlines()

        capture = False

        report_box.insert(tk.END, "ARCHITECTURE SELECTION REASON\n")
        report_box.insert(tk.END, "=============================\n\n")

        for line in lines:

            if "Reason for Selection" in line:
                capture = True
                continue

            if "ARCHITECTURE RANKING" in line:
                capture = False

            if capture:
                report_box.insert(tk.END, line)

        report_box.insert(tk.END, "\n\n")

    if os.path.exists(perf_file):

        report_box.insert(tk.END, "PERFORMANCE REPORT\n")
        report_box.insert(tk.END, "==================\n\n")

        with open(perf_file) as f:
            report_box.insert(tk.END, f.read())


# -----------------------------
# GUI Layout
# -----------------------------
root = tk.Tk()
root.title("Memory Architecture Generator")
root.geometry("750x650")


def add_field(label, placeholder):

    frame = tk.Frame(root)
    frame.pack(pady=4)

    tk.Label(frame, text=label, width=24, anchor="w").pack(side="left")

    entry = PlaceholderEntry(frame, placeholder)
    entry.pack(side="right")

    return entry


memory_size = add_field("Memory Size", "eg. 1024")
data_width = add_field("Data Width", "eg. 8")

num_ports = add_field("Num Ports", "eg. 2")
read_ports = add_field("Read Ports", "eg. 1")
write_ports = add_field("Write Ports", "eg. 1")

num_banks = add_field("Num Banks", "eg. 4")

clock_frequency = add_field("Clock Frequency (MHz)", "eg. 500")

N = add_field("N", "eg. 1")


# Priority dropdown
frame1 = tk.Frame(root)
frame1.pack(pady=6)

tk.Label(frame1, text="Priority", width=24, anchor="w").pack(side="left")

priority = ttk.Combobox(frame1, values=["latency", "bandwidth"])
priority.set("latency")
priority.pack(side="right")


# Access pattern dropdown
frame2 = tk.Frame(root)
frame2.pack(pady=6)

tk.Label(frame2, text="Access Pattern", width=24, anchor="w").pack(side="left")

access_pattern = ttk.Combobox(frame2, values=["random", "sequential"])
access_pattern.set("random")
access_pattern.pack(side="right")


generate_button = tk.Button(
    root,
    text="Generate Architecture",
    command=run_generator,
    height=2,
    width=30
)

generate_button.pack(pady=20)


report_box = tk.Text(root, height=20, width=90)
report_box.pack(pady=10)


root.mainloop()