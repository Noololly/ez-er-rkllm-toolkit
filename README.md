# EZ-ER-RKLLM-Toolkit

## Backstory

I got tired of manually downloading models from HuggingFace using git-lfs, authenticating every time, waiting for that finish, and then FINALLY manually inputting the model source and destination into a Python script, and then wait for THAT to finish inside of a Docker container before moving onto the next one and starting the process all over again.

As a result, I wrote these two scripts to download models from HuggingFace, convert them, pull all .json files from the original repo, and then insert a block of text into the model card (see below) before finally uploading everything to HuggingFace.

Original repo is here: (RKLLM)[https://github.com/airockchip/rknn-llm]

Initial testing was done using Pelochus' EZ RKNN-LLM container found in this repo: (ezrknn-llm)[https://github.com/Pelochus/ezrknn-llm/]

For more information, and useful links, please check out the (RockchipNPU subreddit)[https://reddit.com/r/RockchipNPU]

Conversion tests done on consumer grade hardware:

- AMD Ryzen 3 1200 Quad-Core Processor
- GA-AX370-Gaming K5 Motherboard
- 2 x G.SKILL Ripjaws V Series DDR4 RAM 32GB, 64GB total
- NVIDIA GeForce GTX 780 (not used in this experiment)

Also performed conversion using an Intel X5650 CPU, which uses DDR3 RAM and does not support AVX.

## How to use

There are two scripts in here - an interactive, and a non-interactive version. I have also included version 1.1.0 of RKLLM-Toolkit, since it contains all of the dependencies required to run these scripts (except for inquirer.)

To get started, clone this repository:

```bash
git clone -b v1.1.0 https://github.com/c0zaut/ez-er-rkllm.git
```

To do a one-shot conversion in an interactive shell:

```bash
cd docker-interactive
docker build -t $(whoami)/rkllm-interactive . && docker run -it --rm $(whoami)/rkllm-interactive
```

To do a batch of various models, quant types, with or without optimization mode, and a range of hybrid quant ratios, you will need to edit non_interactive.py by setting the models, qtypes, optimizations, and hybrid quant ratio lists. 

For example, to convert all three versions of chatglm3-6b (8K, 32K, and 128K context windows) with and without optimization, using w8a8 and w8a8_g128 quantizations with hybrid ratios of 0.0, 0.5, and 1.0:

```python
    model_ids = {"THUDM/chatglm3-6b", "THUDM/chatglm3-6b-32k", "THUDM/chatglm3-6b-128k"}
    qtypes = {"w8a8", "w8a8_g128"}
    hybrid_rates = {"0.0", "0.5", "1.0"}
    optimizations = {"0", "1"}
```

Save your changes, and then run the following from the root of the repo directory:

```bash
cd docker-noninteractive
docker build -t $(whoami)/rkllm-noninteractive . && docker run -it --rm $(whoami)/rkllm-noninteractive
```

This version of the script performs one large upload - after all conversion is done.

## Changing the model card template

Of course, feel free to adjust the model card template under the HubHelpers class, which is available in both:

```python
    def build_card(self, export_path):
        """
        Inserts text into the README.md file of the original model, after the model data. 
        Using the HF built-in functions kept omitting the card's model data,
        so gonna do this old school.
        """
        self.model_name = self.model_id.split("/", 1)[1]
        self.card_in = ModelCard.load(self.model_id)
        self.card_out = export_path + "README.md"
        self.template = f'---\n' + \
            f'{self.card_in.data.to_yaml()}\n' + \
            f'---\n' + \
            f'# {self.model_name}-{self.platform.upper()}-{self.rkllm_version}\n\n' + \
            f'This version of {self.model_name} has been converted to run on the {self.platform.upper()} NPU using {self.qtype} quantization.\n\n' + \
            f'This model has been optimized with the following LoRA: {self.lora_id}\n\n' + \
            f'Compatible with RKLLM version: {self.rkllm_version}\n\n' + \
            f'Useful links:\n' + \
            f'(Official RKLLM GitHub)[https://github.com/airockchip/rknn-llm)\n' + \
            f'(RockhipNPU Reddit)[https://reddit.com/r/RockchipNPU]\n' + \
            f'(EZRKNN-LLM)[https://github.com/Pelochus/ezrknn-llm/]\n' + \
            f'Pretty much anything by these folks: (marty1885)[https://github.com/marty1885] and (happyme531)[https://huggingface.co/happyme531]\n' + \
            f'# Original Model Card for base model, {self.model_name}, below:\n\n' + \
            f'{self.card_in.text}'
        try:
            ModelCard.save(self.template, self.card_out)
        except RuntimeError as e:
            print(f"Runtime Error: {e}")
        except RuntimeWarning as w:
            print(f"Runtime Warning: {w}")
        else:
            print(f"Model card successfully exported to {self.card_out}!")
            c = open(self.card_out, 'r')
            print(c.read())
            c.close()
```

## Utilization

Model conversion utilizes anywhere from 2-4x the size of the original model, which means that you need an equal amount of memory. I compensated for this with swap files of varying size. Since I just leave the process running overnight (I have low upload speeds,) the performance hit from using swap files vs partitions doesn't bother me much. If performance is critical, I would recommend at least 512GB of DDR4 RAM with a lot of cores to handle especially large models.

Based on my comparisons of the APIs, these scripts should also be compatible with RKLLM v1.1.1 and Python 3.10. I just haven't tested them yet.

If you do, please be sure to update the hard-coded rkllm-version variable in the RKLLMRemotePipeline class.

To do:

- Test with LoRA
- Test with multimodal models (currently only converted txt2txt)
- Update to use the newer version of RKLLM, 1.1.1 (most likely after 0.9.8 of the kernel driver is in Armbian)