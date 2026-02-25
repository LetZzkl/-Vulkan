#!/system/bin/sh

ui_print "*******************************"
ui_print " Vulkan渲染引擎增强模块 0855 "
ui_print " 基于酷安@甜馒头原版深度优化 "
ui_print "*******************************"
ui_print " "

keytest() {
  ui_print "--------------------------------------"
  ui_print "🔊 $1"
  ui_print "   音量+ : 确认 / 是 (Yes)"
  ui_print "   音量- : 跳过 / 否 (No)"
  ui_print "--------------------------------------"
  
  while true; do
    INPUT=$(timeout 10 getevent -l -c 1 2>&1)
    
    if echo "$INPUT" | grep -q "KEY_VOLUMEUP"; then
      return 0 
    elif echo "$INPUT" | grep -q "KEY_VOLUMEDOWN"; then
      return 1 
    fi
  done
}

get_choose() {
  while true; do
    INPUT=$(timeout 10 getevent -l -c 1 2>&1)
    
    if echo "$INPUT" | grep -q "KEY_VOLUMEUP"; then
      echo "0"
      return 0
    elif echo "$INPUT" | grep -q "KEY_VOLUMEDOWN"; then
      echo "1"
      return 1
    fi
  done
}

go_to_coolapk() {
    ui_print " "
    ui_print "--------------------------------------"
    ui_print "是否关注作者？💘"
    ui_print "● 按音量键＋: 是"
    ui_print "● 按音量键－: 否"
    ui_print "--------------------------------------"
    
    CHOICE=$(get_choose)
    
    if [ "$CHOICE" = "0" ]; then
        UID="34256495"
        ui_print "🔄 检测酷安应用..."
        
        
        if pm list packages | grep -q "com.coolapk.market"; then
            ui_print "✅ 检测到酷安，正在跳转到作者主页..."
            
            am start -d "coolmarket://u/${UID}" >/dev/null 2>&1 ||
            am start -a android.intent.action.VIEW -d "http://www.coolapk.com/u/${UID}" >/dev/null 2>&1 ||
            ui_print "⚠️  无法打开酷安，请手动搜索作者ID: ${UID}"
            ui_print "💘 感谢支持!"
        else
            ui_print "💔 未安装酷安，关注不了QAQ"
            ui_print "📱 请安装酷安后搜索作者ID: 34256495"
        fi
    else
        ui_print "💔 那好吧 QAQ"
    fi
    
    ui_print " "
}


detect_system_type() {
    local IS_COLOROS=false
    if [ -n "$(getprop ro.oplus.version 2>/dev/null)" ] || 
       [ -n "$(getprop ro.oppo.version 2>/dev/null)" ] || 
       [ -n "$(getprop ro.oxygen.version 2>/dev/null)" ] || 
       [ -n "$(getprop ro.vendor.oplus.version 2>/dev/null)" ] || 
       [ -d "/system/system_ext/oplus-build-date" ] || 
       [ -f "/system/system_ext/oplus-build-date" ] || 
       [ -f "/system/system_ext/oplus-build-id" ] || 
       [ -d "/system/system_ext/oplus-rom" ]; then
        IS_COLOROS=true
    fi

    local IS_HYPEROS=false
    if [ "$IS_COLOROS" = "false" ]; then
        if [ -n "$(getprop ro.miui.ui.version.name 2>/dev/null)" ] || 
           [ -n "$(getprop ro.build.version.hyperos 2>/dev/null)" ] || 
           [ -d "/system/product/overlay/HyperOS" ] || 
           [ -f "/system/etc/device_features/hyperos.xml" ] ||
           [ -n "$(getprop ro.miui.build.version 2>/dev/null)" ]; then
            IS_HYPEROS=true
        fi
    fi
    
    local IS_MIUI=false
    if [ "$IS_COLOROS" = "false" ] && [ "$IS_HYPEROS" = "false" ]; then
        if [ -n "$(getprop ro.miui.ui.version.code 2>/dev/null)" ] || 
           [ -n "$(getprop ro.miui.ui.version.name 2>/dev/null)" ] ||
           [ -d "/system/media/theme/miui" ]; then
            IS_MIUI=true
        fi
    fi
    
    local IS_AOSP_LIKE=false
    
    if [ "$IS_COLOROS" = "false" ] && [ "$IS_HYPEROS" = "false" ] && [ "$IS_MIUI" = "false" ]; then
        local BUILD_FLAVOR=$(getprop ro.build.flavor 2>/dev/null)
        local BUILD_TYPE=$(getprop ro.build.type 2>/dev/null)
        local BUILD_TAGS=$(getprop ro.build.tags 2>/dev/null)
        
        if [ ! -z "$BUILD_FLAVOR" ]; then
            case $BUILD_FLAVOR in
                *aosp*|*gapps*|*vanilla*|*lineage*|*arrow*|*crDroid*|*cherish*|*evolution*|*pixel*|*pe*)
                    IS_AOSP_LIKE=true
                    ;;
            esac
        fi
        
        if [ "$BUILD_TAGS" = "release-keys" ] && [ "$BUILD_TYPE" = "userdebug" ]; then
            if echo "$BUILD_FLAVOR" | grep -q -E "aosp|gapps|vanilla"; then
                IS_AOSP_LIKE=true
            fi
        fi
        
        if [ -d "/system/product/overlay" ]; then
            if [ -z "$(getprop ro.oplus.version)" ] && 
               [ -z "$(getprop ro.miui.ui.version.code)" ] && 
               [ -z "$(getprop ro.vendor.oplus.version)" ] && 
               [ -z "$(getprop ro.build.flyme.version)" ] && 
               [ -z "$(getprop ro.samsung.version)" ] &&
               [ -z "$(getprop ro.vivo.version)" ] &&
               [ -z "$(getprop ro.huawei.build.version)" ]; then
                IS_AOSP_LIKE=true
            fi
        fi
    fi
    
    if [ "$IS_COLOROS" = "true" ]; then
        echo "coloros"
    elif [ "$IS_HYPEROS" = "true" ]; then
        echo "hyperos"
    elif [ "$IS_MIUI" = "true" ]; then
        echo "miui"
    elif [ "$IS_AOSP_LIKE" = "true" ]; then
        echo "aosp"
    else
        echo "manufacturer"
    fi
}

detect_gpu_platform() {
    ui_print "🎮 正在检测GPU平台..."
    if [ -f "/sys/class/kgsl/kgsl-3d0/gpu_model" ]; then
        GPU_MODEL=$(cat /sys/class/kgsl/kgsl-3d0/gpu_model 2>/dev/null)
        ui_print "✅ 检测到高通GPU: $GPU_MODEL"
    elif [ ! -z "$(getprop ro.mediatek.platform)" ]; then
        ui_print "✅ 检测到联发科平台"
    elif dmesg | grep -i "mali" >/dev/null 2>&1; then
        ui_print "✅ 检测到ARM Mali GPU"
    else
        ui_print "🔍 GPU平台: 自动检测"
    fi
}

configure_vulkan_optimizations() {
    local VULKAN_VERSION=$1
    local SYSTEM_TYPE=$2
    
    ui_print "⚙️  正在根据Vulkan版本配置优化参数..."
    
    local VULKAN_API_LEVEL_RAW=$(echo "$VULKAN_VERSION" | grep -oE "1\.[0-9]\.?[0-9]?" | tr -d '.')
    
    local VULKAN_API_LEVEL
    if [ ${#VULKAN_API_LEVEL_RAW} -eq 3 ] 2>/dev/null; then
        VULKAN_API_LEVEL="$VULKAN_API_LEVEL_RAW"
    elif [ ${#VULKAN_API_LEVEL_RAW} -eq 2 ] 2>/dev/null; then
        VULKAN_API_LEVEL="${VULKAN_API_LEVEL_RAW}0"
    else
        VULKAN_API_LEVEL="0"
    fi

    local ENABLE_DYNAMIC_RENDERING="false"
    local ENABLE_SYNCHRONIZATION2="false"
    local ENABLE_DESCRIPTOR_INDEXING="false"
    local VULKAN_FEATURE_LEVEL="1.1"
    
    if [ "$VULKAN_API_LEVEL" -ge 130 ] 2>/dev/null; then
        ENABLE_DYNAMIC_RENDERING="true"
        ENABLE_SYNCHRONIZATION2="true"
        ENABLE_DESCRIPTOR_INDEXING="true"
        VULKAN_FEATURE_LEVEL="1.3"
        ui_print "🎯 检测到Vulkan 1.3+，启用高级特性"
    elif [ "$VULKAN_API_LEVEL" -ge 120 ] 2>/dev/null; then
        ENABLE_DESCRIPTOR_INDEXING="true"
        VULKAN_FEATURE_LEVEL="1.2"
        ui_print "🎯 检测到Vulkan 1.2，启用中级特性"
    elif [ "$VULKAN_API_LEVEL" -ge 110 ] 2>/dev/null; then
        VULKAN_FEATURE_LEVEL="1.1"
        ui_print "🎯 检测到Vulkan 1.1+，使用基础特性"
    else
        VULKAN_FEATURE_LEVEL="1.1"
        ui_print "⚠️  无法确定Vulkan版本，使用兼容配置 (1.1)"
    fi
    
    local LAYER_CACHING="false"
    case $SYSTEM_TYPE in
        "hyperos"|"aosp"|"coloros")
            LAYER_CACHING="false"
            ui_print "⚠️  $SYSTEM_TYPE: 已禁用图层缓存"
            ;;
        "miui"|"manufacturer")
            LAYER_CACHING="true"
            ui_print "✅ $SYSTEM_TYPE: 已启用图层缓存"
            ;;
        *)
            LAYER_CACHING="false"
            ui_print "⚠️  未知系统类型: 保守禁用图层缓存"
            ;;
    esac
    
    cat > $MODPATH/system.prop << EOF
ro.hwui.use_vulkan=true
debug.hwui.renderer=skiavk
debug.renderengine.backend=skiavkthreaded
debug.renderengine.vulkan=true
debug.stagefright.renderengine.backend=threaded
debug.hwui.vulkan_feature_level=1.3
debug.hwui.vulkan.enable_dynamic_rendering=true
debug.hwui.vulkan.synchronization2=true
debug.hwui.vulkan.enable_descriptor_indexing=true
debug.hwui.vulkan.force_basic_features=1
debug.hwui.vulkan.legacy_mode=true
debug.hwui.vulkan.1_1.compatible_mode=true
debug.hwui.vulkan.platform_optimized=true
debug.hwui.vulkan.auto_detect_features=true
debug.hwui.vulkan.adreno.prefer_buffer_bounds_check=1
debug.hwui.vulkan.mali.prefer_split_fragment_descriptor_sets=1
ro.surface_flinger.max_frame_buffer_acquired_buffers=3
ro.surface_flinger.min_acquired_buffers=1
debug.hwui.use_hint_manager=true
debug.hwui.target_cpu_time_percent=70
debug.hwui.vulkan.robust_buffer_access=true
debug.hwui.vulkan.fallback_to_legacy_pipeline=true
debug.hwui.fallback_renderer=skiagl
debug.hwui.initialize_gl_always=true
debug.hwui.level=0
debug.renderengine.skia_atrace_enabled=false
debug.sf.enable_adpf_cpu_hint=false

#图层缓存属性（强！(⸝⸝•‧̫•⸝⸝)）
debug.sf.enable_layer_caching=$LAYER_CACHING
EOF

    ui_print "✅ 系统属性配置完成"
}

ui_print "🚀 开始安装Vulkan优化模块 0855..."

ui_print " "
if keytest "请按键选择: 是否启用 Vulkan 1.3 ?"; then
    VULKAN_VERSION="1.3"
else
    ui_print "👉 跳过 1.3，进入下一选项..."
    sleep 1
    
    if keytest "请按键选择: 是否启用 Vulkan 1.2 ?"; then
        VULKAN_VERSION="1.2"
    else
        ui_print "👉 跳过 1.2，默认使用 1.1"
        VULKAN_VERSION="1.1"
    fi
fi

detect_gpu_platform
ui_print "🔍 正在检测系统类型..."
SYSTEM_TYPE=$(detect_system_type)
ui_print "📱 检测到系统类型: $SYSTEM_TYPE"

configure_vulkan_optimizations "$VULKAN_VERSION" "$SYSTEM_TYPE"

set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive $MODPATH/system 0 0 0755 0644

go_to_coolapk

ui_print " "
ui_print "🎯 安装摘要:"
ui_print "   • Vulkan版本: $VULKAN_VERSION"
ui_print "   • 系统类型: $SYSTEM_TYPE"
ui_print "   • 平台专属优化已启用"
ui_print "   • 兼容性保障已就绪"
ui_print " "
ui_print "✨ 刷入成功!请重启系统生效"
ui_print "💡 如有问题请到酷安反馈详细系统信息" 