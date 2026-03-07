import yaml
import os
import math
from jinja2 import Environment, FileSystemLoader

# -------------------------------------
# Paths
# -------------------------------------

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

TEMPLATE_DIR = os.path.join(SCRIPT_DIR, "templates")
RESULT_DIR = os.path.join(SCRIPT_DIR, "results")

# -------------------------------------
# Load input.yaml
# -------------------------------------

def load_input():

    input_file = os.path.join(SCRIPT_DIR, "input.yaml")

    with open(input_file) as f:
        return yaml.safe_load(f)


# -------------------------------------
# Architecture Selection
# -------------------------------------

def select_architecture(cfg):

    if cfg["num_ports"] > 4:
        return "Multiport_Arch"

    if cfg["read_ports"] > 2:
        return "replicated"

    if cfg["priority"] == "bandwidth":
        return "banked"

    if cfg["clock_frequency"] > 700:
        return "pipelined"

    if cfg["access_pattern"] == "sequential":
        return "interleaved"

    return "monolithic"


# -------------------------------------
# Compute Parameters
# -------------------------------------

def compute_parameters(cfg):

    params = {}

    params["DATA_WIDTH"] = cfg["data_width"]
    params["MEMORY_SIZE"] = cfg["memory_size"]

    memory_depth = cfg["memory_size"] // cfg["data_width"]
    params["MEMORY_DEPTH"] = memory_depth

    addr_width = math.ceil(math.log2(memory_depth))
    params["ADDR_WIDTH"] = addr_width

    params["NUM_PORTS"] = cfg["num_ports"]

    params["NUM_READ_PORTS"] = cfg["read_ports"]
    params["NUM_WRITE_PORTS"] = cfg["write_ports"]

    # required by some RTL templates
    params["READ_PORTS"] = cfg["read_ports"]
    params["WRITE_PORTS"] = cfg["write_ports"]

    params["N"] = cfg["N"]

    params["NUM_BANKS"] = cfg["num_banks"]
    params["MAX_BANKS"] = cfg["num_banks"]

    bank_index_width = math.ceil(math.log2(cfg["num_banks"]))
    params["BANK_INDEX_WIDTH"] = bank_index_width

    params["BANK_ADDR_WIDTH"] = addr_width - bank_index_width

    if cfg["clock_frequency"] > 700:
        params["PIPELINE_DEPTH"] = 3
    else:
        params["PIPELINE_DEPTH"] = 1

    params["CLOCK_FREQUENCY"] = cfg["clock_frequency"]
    params["ACCESS_PATTERN"] = cfg["access_pattern"]
    params["PRIORITY"] = cfg["priority"]

    # arbiter + address mapping
    arb_map = {
        "round_robin": 0,
        "priority": 1,
        "age_based": 2
    }

    addr_map = {
        "block": 0,
        "interleaved": 1,
        "xor": 2
    }

    priority_map = {
    "latency": 0,
    "bandwidth": 1
}

    access_map = {
    "random": 0,
    "sequential": 1
}

    params["PRIORITY"] = priority_map.get(cfg["priority"], 0)
    params["ACCESS_PATTERN"] = access_map.get(cfg["access_pattern"], 0)

    params["ARBITER_TYPE"] = arb_map.get(cfg.get("arbiter_type", "round_robin"), 0)
    params["ADDR_MAP_TYPE"] = addr_map.get(cfg.get("addr_map_type", "block"), 0)

    return params


# -------------------------------------
# Create Output Directories
# -------------------------------------

def create_result_dirs(arch):

    base = os.path.join(RESULT_DIR, arch)

    rtl_dir = os.path.join(base, "rtl")
    tb_dir = os.path.join(base, "tb")
    report_dir = os.path.join(base, "reports")

    os.makedirs(rtl_dir, exist_ok=True)
    os.makedirs(tb_dir, exist_ok=True)
    os.makedirs(report_dir, exist_ok=True)

    return rtl_dir, tb_dir, report_dir


# -------------------------------------
# Generate Architecture RTL
# -------------------------------------

def generate_architecture_rtl(arch, params):

    env = Environment(loader=FileSystemLoader(TEMPLATE_DIR))

    rtl_dir, _, _ = create_result_dirs(arch)

    arch_folder = os.path.join(TEMPLATE_DIR, "architectures", arch)

    if not os.path.exists(arch_folder):
        print("ERROR: Architecture template not found:", arch_folder)
        return

    for root, dirs, files in os.walk(arch_folder):

        for file in files:

            if file.endswith(".j2"):

                full_path = os.path.join(root, file)

                rel_path = os.path.relpath(full_path, TEMPLATE_DIR)
                rel_path = rel_path.replace("\\", "/")

                template = env.get_template(rel_path)

                rendered = template.render(params)

                output_name = file.replace(".j2", "")

                output_path = os.path.join(rtl_dir, output_name)

                with open(output_path, "w") as f:
                    f.write(rendered)

                print("Generated RTL:", output_path)


# -------------------------------------
# Generate Shared Modules
# -------------------------------------

def generate_shared_modules(arch, cfg, params):

    env = Environment(loader=FileSystemLoader(TEMPLATE_DIR))

    rtl_dir, _, _ = create_result_dirs(arch)

    # -----------------------------
    # Address Mapping
    # -----------------------------

    if arch == "pipelined":
        addr_type = "interleaved"
    else:
        addr_type = cfg.get("addr_map_type", "block")

    addr_template = f"shared_modules/address_mapping/address_map_{addr_type}.v.j2"

    template = env.get_template(addr_template)

    rendered = template.render(params)

    output = os.path.join(rtl_dir, f"address_map_{addr_type}.v")

    with open(output, "w") as f:
        f.write(rendered)

    print("Generated:", output)

    # -----------------------------
    # Arbiter
    # -----------------------------

    arbiter_type = cfg.get("arbiter_type", "round_robin")

    arb_template = f"shared_modules/arbiters/arbiter_{arbiter_type}.v.j2"

    template = env.get_template(arb_template)

    rendered = template.render(params)

    output = os.path.join(rtl_dir, f"arbiter_{arbiter_type}.v")

    with open(output, "w") as f:
        f.write(rendered)

    print("Generated:", output)

    # -----------------------------
    # Memory Modules
    # -----------------------------

    mem_folder = os.path.join(TEMPLATE_DIR, "shared_modules", "memory")

    for file in os.listdir(mem_folder):

        if not file.endswith(".j2"):
            continue

        if file == "write_broadcast.v.j2" and arch != "replicated":
            continue

        if file == "read_mux.v.j2" and cfg["read_ports"] <= 1:
            continue

        template_path = f"shared_modules/memory/{file}"

        template = env.get_template(template_path)

        rendered = template.render(params)

        output_name = file.replace(".j2", "")

        output = os.path.join(rtl_dir, output_name)

        with open(output, "w") as f:
            f.write(rendered)

        print("Generated:", output)

    # -----------------------------
    # Pipeline Modules
    # -----------------------------

    if arch == "pipelined":

        pipe_folder = os.path.join(TEMPLATE_DIR, "shared_modules", "pipeline")

        for file in os.listdir(pipe_folder):

            if file.endswith(".j2"):

                template_path = f"shared_modules/pipeline/{file}"

                template = env.get_template(template_path)

                rendered = template.render(params)

                output_name = file.replace(".j2", "")

                output = os.path.join(rtl_dir, output_name)

                with open(output, "w") as f:
                    f.write(rendered)

                print("Generated:", output)


# -------------------------------------
# Generate Testbench
# -------------------------------------

def generate_testbench(arch, params):

    env = Environment(loader=FileSystemLoader(TEMPLATE_DIR))

    _, tb_dir, _ = create_result_dirs(arch)

    template = env.get_template("testbench/memory_tb.v.j2")

    rendered = template.render(params)

    tb_file = os.path.join(tb_dir, f"{arch}_memory_tb.v")

    with open(tb_file, "w") as f:
        f.write(rendered)

    print("Generated Testbench:", tb_file)


# -------------------------------------
# Generate Report
# -------------------------------------

def generate_report(arch, cfg, params):

    _, _, report_dir = create_result_dirs(arch)

    report_file = os.path.join(report_dir, "architecture_report.txt")

    with open(report_file, "w") as f:

        f.write("MEMORY ARCHITECTURE REPORT\n")
        f.write("===========================\n\n")

        f.write("Selected Architecture\n")
        f.write("---------------------\n")
        f.write(f"{arch}\n\n")

        f.write("User Inputs\n")
        f.write("-----------\n")

        for k, v in cfg.items():
            f.write(f"{k}: {v}\n")

        f.write("\nDerived Parameters\n")
        f.write("------------------\n")

        for k, v in params.items():
            f.write(f"{k}: {v}\n")

    print("Generated Report:", report_file)


# -------------------------------------
# Main
# -------------------------------------

def main():

    cfg = load_input()

    arch = select_architecture(cfg)

    print("\nSelected Architecture:", arch)

    params = compute_parameters(cfg)

    params["ARCHITECTURE"] = arch

    generate_architecture_rtl(arch, params)

    generate_shared_modules(arch, cfg, params)

    generate_testbench(arch, params)

    generate_report(arch, cfg, params)

    print("\nGeneration Completed")

    print("\nResults located at:")

    print(f"{RESULT_DIR}/{arch}/")

    print("\nRun simulation using:")

    print(f"""
cd results/{arch}/tb
iverilog -o sim ../rtl/*.v *.v
vvp sim
""")

if __name__ == "__main__":
    main()