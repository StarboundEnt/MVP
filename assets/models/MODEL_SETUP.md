# Gemma Model Setup for Starbound

This directory contains AI models for on-device inference using Google's Gemma models.

## Quick Setup

### Option 1: Recommended - Gemma 3 Nano 1B (Fast & Lightweight)
1. Go to [Kaggle Gemma Models](https://www.kaggle.com/models/google/gemma-2)
2. Download **Gemma 3 Nano 1B** model (~529MB)
3. Place the `.tflite` file in this directory as `gemma-3-nano-1b.tflite`

### Option 2: Alternative - Gemma 2B (More Capable)
1. Download **Gemma 2B** model (~2GB) from Kaggle
2. Place it as `gemma-2b.tflite`

## File Structure
```
assets/models/
├── MODEL_SETUP.md (this file)
├── gemma-3-nano-1b.tflite (download this)
└── gemma-2b.tflite (optional, larger model)
```

## Model Comparison

| Model | Size | Speed | Quality | Best For |
|-------|------|-------|---------|----------|
| Gemma 3 Nano 1B | ~529MB | Very Fast | Good | Ask Starbound, Quick responses |
| Gemma 2B | ~2GB | Fast | Better | Health forecasting, Complex analysis |

## Download Instructions

1. **Create Kaggle Account**: Visit [kaggle.com](https://kaggle.com) and sign up
2. **Find Gemma Models**: Search for "Gemma" in the Models section
3. **Download**: Click on your preferred model and download the `.tflite` version
4. **Place in Directory**: Move the downloaded file to this `assets/models/` directory
5. **Rename**: Ensure the filename matches what's expected in the code

## Verification

After downloading, your `assets/models/` directory should contain:
- ✅ At least one `.tflite` file
- ✅ This setup guide

## Next Steps

Once you've downloaded a model:
1. The app will automatically detect and load it
2. AI responses will switch from simulation to real inference
3. You'll get much more intelligent and contextual responses!

## Troubleshooting

**Model too large?** 
- Start with Gemma 3 Nano 1B (529MB)
- It provides excellent quality for most use cases

**Download issues?**
- Make sure you're logged into Kaggle
- Some models require agreeing to terms of use
- Try downloading via browser if CLI fails

**App not loading model?**
- Check the filename matches exactly
- Ensure the file isn't corrupted (re-download if needed)
- Check app logs for error messages