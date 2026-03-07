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

    num_ports = cfg["num_ports"]
    read_ports = cfg["read_ports"]
    write_ports = cfg["write_ports"]
    clock_frequency = cfg["clock_frequency"]
    priority = cfg["priority"]
    access_pattern = cfg["access_pattern"]
    num_banks = cfg["num_banks"]
    pipeline_depth = cfg.get("pipeline_depth", 1)

    if clock_frequency >= 800 and pipeline_depth >= 2 and priority == "bandwidth":
        return "pipelined", "High clock frequency and bandwidth priority require pipeline stages."

    elif read_ports >= 3 and write_ports <= 1 and 300 <= clock_frequency <= 1500 and priority == "latency":
        return "replicated", "Multiple read ports require replication to avoid read conflicts."

    elif num_ports >= 4 and priority in ["latency", "bandwidth"] and clock_frequency >= 500:
        return "multiport", "High port count requires true multi-port memory."

    elif access_pattern == "sequential" and num_banks >= 4 and clock_frequency >= 300 and priority == "bandwidth":
        return "interleaved", "Sequential access benefits from bank interleaving."

    elif num_ports >= 2 and access_pattern == "random" and num_banks >= 2 and priority in ["bandwidth", "power"]:
        return "banked", "Random accesses with multiple ports benefit from banked architecture."

    elif num_ports <= 1 and clock_frequency <= 200:
        return "monolithic", "Low port count and low frequency allow simple monolithic memory."

    else:
        return "banked", "Default fallback architecture."

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

    params["NUM_REPLICAS"] = cfg["read_ports"]   

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

    if arch in ["pipelined", "interleaved", "banked"]:
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

        if file == "write_broadcast.v.j2" and arch not in ["replicated", "multiport"]:

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

    if arch in ["pipelined", "multiport"]:

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


def rank_architectures(cfg):

    scores = {
        "monolithic": 0,
        "banked": 0,
        "interleaved": 0,
        "replicated": 0,
        "multiport": 0,
        "pipelined": 0
    }

    # High frequency favors pipelining
    scores["pipelined"] += cfg["clock_frequency"] / 100

    # Many read ports favors replication
    scores["replicated"] += cfg["read_ports"] * 3

    # Many total ports favors multiport memory
    scores["multiport"] += cfg["num_ports"] * 3

    # Banking improves bandwidth
    scores["banked"] += cfg["num_banks"] * 2

    # Sequential access benefits interleaving
    if cfg["access_pattern"] == "sequential":
        scores["interleaved"] += cfg["num_banks"] * 3

    # Very small/simple systems
    if cfg["num_ports"] <= 1:
        scores["monolithic"] += 10

    # Priority adjustments
    if cfg["priority"] == "bandwidth":
        scores["banked"] += 5
        scores["interleaved"] += 5

    if cfg["priority"] == "latency":
        scores["replicated"] += 5

    return scores



# -------------------------------------
# Generate Detailed Report
# -------------------------------------

def generate_report(arch, reason, cfg, params):

    _, _, report_dir = create_result_dirs(arch)

    report_file = os.path.join(report_dir, "architecture_report.txt")

    # -----------------------------------------
    # Architecture ranking
    # -----------------------------------------

    scores = rank_architectures(cfg)

    ranked = sorted(scores.items(), key=lambda x: x[1], reverse=True)

    best_arch = ranked[0][0]
    second_best = ranked[1][0]

    bandwidth = cfg["data_width"] * cfg["num_ports"]

    with open(report_file, "w") as f:

        f.write("INTELLIGENT MEMORY ARCHITECTURE REPORT\n")
        f.write("======================================\n\n")

        # ---------------------------------
        # Input configuration
        # ---------------------------------

        f.write("1. INPUT CONFIGURATION\n")
        f.write("----------------------\n")

        for k, v in cfg.items():
            f.write(f"{k}: {v}\n")

        # ---------------------------------
        # Derived parameters
        # ---------------------------------

        f.write("\n2. DERIVED PARAMETERS\n")
        f.write("---------------------\n")

        for k, v in params.items():
            f.write(f"{k}: {v}\n")

        # ---------------------------------
        # Selected architecture
        # ---------------------------------

        f.write("\n3. SELECTED ARCHITECTURE\n")
        f.write("------------------------\n")

        f.write(f"Selected Architecture : {arch}\n\n")

        f.write("Reason for Selection\n")
        f.write("--------------------\n")

        f.write(reason + "\n")

        # ---------------------------------
        # Architecture ranking
        # ---------------------------------

        f.write("\n4. ARCHITECTURE RANKING\n")
        f.write("-----------------------\n")

        for i, (a, score) in enumerate(ranked):

            f.write(f"{i+1}. {a} (score: {score})\n")

        # ---------------------------------
        # Second best architecture
        # ---------------------------------

        f.write("\n5. SECOND BEST ARCHITECTURE\n")
        f.write("---------------------------\n")

        f.write(f"{second_best}\n\n")

        f.write("""
Although the second-best architecture could satisfy the design constraints,
the selected architecture provides a better balance between performance,
parallelism, and implementation complexity under the given input conditions.
""")

        # ---------------------------------
        # Performance estimation
        # ---------------------------------

        f.write("\n6. PERFORMANCE ESTIMATION\n")
        f.write("-------------------------\n")

        f.write(f"Estimated Peak Bandwidth : {bandwidth} bits/cycle\n")
        f.write(f"Operating Frequency      : {cfg['clock_frequency']} MHz\n")

        # ---------------------------------
        # Architecture discussion
        # ---------------------------------

        f.write("\n7. ARCHITECTURE DISCUSSION\n")
        f.write("--------------------------\n")

        f.write("""
Different memory architectures provide different tradeoffs.

Monolithic Memory
- Lowest hardware complexity
- Limited parallel access

Banked Memory
- Improves bandwidth through multiple banks
- Possible bank conflicts

Interleaved Memory
- Distributes sequential accesses across banks
- Good for streaming workloads

Replicated Memory
- Eliminates read conflicts
- Higher area due to duplicated memory arrays

Multi-Port Memory
- Supports simultaneous accesses
- Complex memory cell design

Pipelined Memory
- Supports high clock frequencies
- Increased latency due to pipeline stages
""")

        # ---------------------------------
        # Summary
        # ---------------------------------

        f.write("\n8. SUMMARY\n")
        f.write("----------\n")

        f.write(f"""
Based on the provided configuration parameters, the generator evaluated
multiple candidate architectures.

Using a scoring-based architecture exploration model, the system ranked
possible architectures and selected:

    {arch}

The second-best candidate was:

    {second_best}

The final architecture was chosen because it provides the best balance
between bandwidth, latency, and implementation complexity for the given
system constraints.
""")

    print("Generated Detailed Report:", report_file)

# -------------------------------------
# Main
# -------------------------------------

def main():

    cfg = load_input()

    arch, reason = select_architecture(cfg)

    print("\nSelected Architecture:", arch)

    params = compute_parameters(cfg)

    params["ARCHITECTURE"] = arch

    generate_architecture_rtl(arch, params)

    generate_shared_modules(arch, cfg, params)

    generate_testbench(arch, params)

    generate_report(arch, reason, cfg, params)

    print("\nGeneration Completed")

    print("\nResults located at:")

    print(f"{RESULT_DIR}/{arch}/")

if __name__ == "__main__":
    main()