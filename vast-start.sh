#!/bin/bash

source /venv/main/bin/activate
COMFYUI_DIR=${WORKSPACE}/ComfyUI

# =========================
# OPTIONAL PACKAGES
# =========================
APT_PACKAGES=(
    ffmpeg
)

PIP_PACKAGES=(
    pydub
    boto3
    fastapi
    uvicorn
    requests
    flask
    Pillow
    emoji==1.7.0
    openai
)

# =========================
# COMFYUI CUSTOM NODES
# =========================
NODES=(
    #"https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/Kijai/ComfyUI-WanVideoWrapper.git"
    "https://github.com/Kijai/ComfyUI-KJNodes.git"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
    "https://github.com/Kijai/ComfyUI-MelBandRoFormer.git"
)

WORKFLOWS=(
)

# =========================
# MODELS
# =========================

CHECKPOINT_MODELS=(
)

UNET_MODELS=(
)

DIFFUSION_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/InfiniteTalk/Wan2_1-InfiniteTalk-Multi_fp8_e5m2_scaled_KJ.safetensors"
    "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/InfiniteTalk/Wan2_1-InfiniteTalk-Single_fp8_e4m3fn_scaled_KJ.safetensors"
    "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/I2V/Wan2_1-I2V-14B-480p_fp8_e5m2_scaled_KJ.safetensors"
    "https://huggingface.co/Kijai/MelBandRoFormer_comfy/resolve/main/MelBandRoformer_fp32.safetensors"
)

VAE_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
)

TEXT_ENCODER_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
)

LORA_MODELS=(
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"
)

UPSCALE_MODELS=(
    "https://huggingface.co/lokCX/4x-Ultrasharp/resolve/main/4x-UltraSharp.pth"
)

CLIP_VISION_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
)

AUDIO_ENCODER_MODELS=(
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/audio_encoders/wav2vec2_large_english_fp16.safetensors"
)

CONTROLNET_MODELS=(
)

# =========================
# PROVISIONING LOGIC
# =========================

function restart_comfyui() {
    echo "🔄 Restarting ComfyUI..."

    # Kill existing ComfyUI process if running
    pkill -f "python.*main.py" || true

    # Small delay to release GPU / ports
    sleep 3

    # Start ComfyUI again (background)
    nohup python "${COMFYUI_DIR}/main.py" \
        --listen 0.0.0.0 \
        --port 8188 \
        > "${WORKSPACE}/comfyui.log" 2>&1 &

    echo "✅ ComfyUI restarted"
}

function fetch_vastainode_assets() {
    local OWNER="denisbalon"
    local REPO="vastainode"
    local TMP_DIR="/tmp/vastainode"
    local DEST="${WORKSPACE}"

    if [[ -z "$GITHUB_TOKEN" ]]; then
        echo "❌ GITHUB_TOKEN not set, cannot fetch private repo"
        return 1
    fi

    echo "⬇️  Fetching assets from private repo: vastainode"

    # Clone or update temp repo
    git clone --depth=1 \
        "https://x-access-token:${GITHUB_TOKEN}@github.com/${OWNER}/${REPO}.git" \
        "$TMP_DIR"

    # ===== Fonts (keep subfolder) =====
    echo "📁 Copying Fonts/"
    mkdir -p "$DEST/Fonts"
    rsync -a "$TMP_DIR/Fonts/" "$DEST/Fonts/"

    # ===== Files copied directly into WORKSPACE =====
    echo "📄 Copying scripts and config files to workspace root"

    cp -f "$TMP_DIR/FFMPEG/add_captions.py" "$DEST/"
    cp -f "$TMP_DIR/FFMPEG/trim_video.py" "$DEST/"

    cp -f "$TMP_DIR/Creds/AWS_CREDENTIALS.json" "$DEST/"
    cp -f "$TMP_DIR/Creds/OPENAI_API_KEY.json" "$DEST/"

    cp -f "$TMP_DIR/Prompts/gpt_speech_text_prompt.txt" "$DEST/"

    cp -f "$TMP_DIR/InfiniteTalk/InfiniteAPI.py" "$DEST/"

    echo "✅ vastainode assets copied to workspace"
}

function start_custom_apis() {
    echo "🚀 Starting custom APIs..."

    cd "${WORKSPACE}"

    # ---- InfiniteAPI ----
    if pgrep -f "python.*InfiniteAPI.py" > /dev/null; then
        echo "✅ InfiniteAPI already running"
    else
        echo "▶ Starting InfiniteAPI..."
        nohup python InfiniteAPI.py \
            > "${WORKSPACE}/InfiniteAPI.log" 2>&1 &
    fi

    # ---- trim_video API / script ----
    if pgrep -f "python.*trim_video.py" > /dev/null; then
        echo "✅ trim_video already running"
    else
        echo "▶ Starting trim_video..."
        nohup python trim_video.py \
            > "${WORKSPACE}/trim_video.log" 2>&1 &
    fi

    echo "✅ Custom APIs started"
}


function provisioning_start() {
    # provisioning_print_header
    # provisioning_get_apt_packages
    # provisioning_get_nodes
    # provisioning_get_pip_packages

    # provisioning_get_files "$COMFYUI_DIR/models/checkpoints" "${CHECKPOINT_MODELS[@]}"
    # provisioning_get_files "$COMFYUI_DIR/models/unet" "${UNET_MODELS[@]}"
    # provisioning_get_files "$COMFYUI_DIR/models/diffusion_models" "${DIFFUSION_MODELS[@]}"
    # provisioning_get_files "$COMFYUI_DIR/models/vae" "${VAE_MODELS[@]}"
    # provisioning_get_files "$COMFYUI_DIR/models/text_encoders" "${TEXT_ENCODER_MODELS[@]}"
    # provisioning_get_files "$COMFYUI_DIR/models/loras" "${LORA_MODELS[@]}"
    # provisioning_get_files "$COMFYUI_DIR/models/upscale_models" "${UPSCALE_MODELS[@]}"
    # provisioning_get_files "$COMFYUI_DIR/models/clip_vision" "${CLIP_VISION_MODELS[@]}"
    # provisioning_get_files "$COMFYUI_DIR/models/audio_encoders" "${AUDIO_ENCODER_MODELS[@]}"
    # provisioning_get_files "$COMFYUI_DIR/models/controlnet" "${CONTROLNET_MODELS[@]}"

    fetch_vastainode_assets
    # restart_comfyui
    start_custom_apis

    # provisioning_print_end
}

function provisioning_get_apt_packages() {
    if [[ -n $APT_PACKAGES ]]; then
        sudo $APT_INSTALL ${APT_PACKAGES[@]}
    fi
}

function provisioning_get_pip_packages() {
    if [[ -n $PIP_PACKAGES ]]; then
        pip install --no-cache-dir ${PIP_PACKAGES[@]}
    fi
}

function provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="${COMFYUI_DIR}/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                echo "Updating node: $repo"
                ( cd "$path" && git pull )
                [[ -e $requirements ]] && pip install --no-cache-dir -r "$requirements"
            fi
        else
            echo "Cloning node: $repo"
            git clone "$repo" "$path" --recursive
            [[ -e $requirements ]] && pip install --no-cache-dir -r "$requirements"
        fi
    done
}

function provisioning_get_files() {
    [[ -z $2 ]] && return 0
    dir="$1"
    mkdir -p "$dir"
    shift
    for url in "$@"; do
        echo "Downloading: $url"
        provisioning_download "$url" "$dir"
    done
}

function provisioning_download() {
    local url="$1"
    local dir="$2"
    local auth_token=""

    if [[ -n $HF_TOKEN && $url =~ huggingface\.co ]]; then
        auth_token="$HF_TOKEN"
    elif [[ -n $CIVITAI_TOKEN && $url =~ civitai\.com ]]; then
        auth_token="$CIVITAI_TOKEN"
    fi

    if [[ -n $auth_token ]]; then
        wget -qnc --content-disposition \
            --header="Authorization: Bearer $auth_token" \
            --show-progress -P "$dir" "$url"
    else
        wget -qnc --content-disposition \
            --show-progress -P "$dir" "$url"
    fi
}

function provisioning_print_header() {
    echo "=============================================="
    echo "  Provisioning ComfyUI + Wan / InfiniteTalk"
    echo "  This may take a while (large models)"
    echo "=============================================="
}

function provisioning_print_end() {
    echo "✅ Provisioning complete"
}

if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi
