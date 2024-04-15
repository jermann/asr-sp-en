from datasets import load_dataset

def main():
    cv_16 = load_dataset("mozilla-foundation/common_voice_16_1", "en" split="dev")
    cv_16.save_to_disk('cv_16-1_en')

if __name__ == "__main__":
    main()
