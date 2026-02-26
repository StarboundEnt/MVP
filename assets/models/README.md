# AI Models Directory

This directory contains the AI models used by Starbound for on-device inference.

## Models

### Gemma 2B IT (Instruction Tuned)
- **File**: `gemma-2b-it.bin`
- **Purpose**: On-device personalized nudge generation
- **Size**: ~2.5GB
- **Download**: This model needs to be downloaded separately due to size constraints

### Tokenizer
- **File**: `tokenizer.model`
- **Purpose**: Text tokenization for Gemma model
- **Size**: ~500KB

## Setup Instructions

1. **Download Gemma 2B Model**:
   ```bash
   # Option 1: From Hugging Face
   curl -L "https://huggingface.co/google/gemma-2b-it/resolve/main/model.bin" -o assets/models/gemma-2b-it.bin
   
   # Option 2: Using git-lfs (if available)
   git lfs pull
   ```

2. **Download Tokenizer**:
   ```bash
   curl -L "https://huggingface.co/google/gemma-2b-it/resolve/main/tokenizer.model" -o assets/models/tokenizer.model
   ```

3. **Verify Files**:
   - `gemma-2b-it.bin` should be approximately 2.5GB
   - `tokenizer.model` should be approximately 500KB

## Model Configuration

The models are configured in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/
```

## Privacy & Security

- All models run locally on-device
- No user data is sent to external servers
- Models are loaded into secure memory space
- Inference happens in isolated threads

## Performance

- Model loading: 3-5 seconds on first app launch
- Inference time: 500-2000ms per request
- Memory usage: ~1GB additional RAM when loaded
- Battery impact: Minimal during inference

## Fallbacks

If models fail to load or are unavailable:
1. Service gracefully falls back to behavioral science rules
2. User experience remains uninterrupted
3. Error messages are user-friendly
4. Performance monitoring tracks fallback usage

## Updates

Models are version-controlled and can be updated via:
1. App store updates (bundled)
2. Over-the-air updates (future feature)
3. Manual download for development

## Troubleshooting

### Model Loading Issues
- Check file sizes and integrity
- Verify storage permissions
- Clear app cache and retry
- Check device storage space (minimum 3GB free)

### Performance Issues
- Close other apps to free memory
- Restart the app
- Check device compatibility
- Monitor CPU temperature

### Quality Issues
- Report through in-app feedback
- Provide context and examples
- Check user profile completeness
- Verify habit data accuracy