# -*- coding: utf-8 -*-
"""
build_hexagrams_json.py
解析 iching-data/ 中的 64 个 .text 文件，生成完整的 hexagrams.json
用法：python build_hexagrams_json.py
输出：../game/hexagrams.json
"""

import os
import re
import json

# ─────────────────────────────────────────────
# 1. 二进制码 → 卦名（来自 crawler.py 中的 dt 字典）
# ─────────────────────────────────────────────
BINARY_TO_NAME = {
    '111111': '乾', '011111': '夬', '000000': '坤', '010001': '屯',
    '100010': '蒙', '010111': '需', '111010': '讼', '000010': '师',
    '010000': '比', '110111': '小畜', '111011': '履', '000111': '泰',
    '111000': '否', '111101': '同人', '10111': '大有', '000100': '谦',
    '001000': '豫', '011001': '随', '100110': '蛊', '000011': '临',
    '110000': '观', '101001': '噬嗑', '100101': '贲', '100000': '剥',
    '000001': '复', '111001': '无妄', '100111': '大畜', '100001': '颐',
    '011110': '大过', '010010': '坎', '101101': '离', '011100': '咸',
    '001110': '恒', '111100': '遁', '001111': '大壮', '101000': '晋',
    '000101': '明夷', '110101': '家人', '101011': '睽', '010100': '蹇',
    '001010': '解', '100011': '损', '110001': '益', '111110': '姤',
    '011000': '萃', '000110': '升', '011010': '困', '010110': '井',
    '011101': '革', '101110': '鼎', '001001': '震', '100100': '艮',
    '110100': '渐', '001011': '归妹', '001101': '丰', '101100': '旅',
    '110110': '巽', '011011': '兑', '110010': '涣', '010011': '节',
    '110011': '中孚', '001100': '小过', '010101': '既济', '101010': '未济'
}

# 反向：卦名 → 二进制码
NAME_TO_BINARY = {v: k for k, v in BINARY_TO_NAME.items()}

# ─────────────────────────────────────────────
# 2. 易经传统序号（King Wen 次序），卦名 → id
# ─────────────────────────────────────────────
KING_WEN_ORDER = [
    '乾', '坤', '屯', '蒙', '需', '讼', '师', '比',
    '小畜', '履', '泰', '否', '同人', '大有', '谦', '豫',
    '随', '蛊', '临', '观', '噬嗑', '贲', '剥', '复',
    '无妄', '大畜', '颐', '大过', '坎', '离', '咸', '恒',
    '遁', '大壮', '晋', '明夷', '家人', '睽', '蹇', '解',
    '损', '益', '姤', '萃', '升', '困', '井', '革',
    '鼎', '震', '艮', '渐', '归妹', '丰', '旅', '巽',
    '兑', '涣', '节', '中孚', '小过', '既济', '未济', '夬'  # 注意夬排在最后
]

NAME_TO_ID = {name: idx + 1 for idx, name in enumerate(KING_WEN_ORDER)}
ID_TO_NAME = {v: k for k, v in NAME_TO_ID.items()}

# ─────────────────────────────────────────────
# 3. 八卦的 Unicode 符号（上卦、下卦 → 卦符）
# ─────────────────────────────────────────────
TRIGRAM_SYMBOLS = {
    '111': '☰',  # 乾 (Heaven)
    '000': '☷',  # 坤 (Earth)
    '001': '☳',  # 震 (Thunder)
    '010': '☵',  # 坎 (Water)
    '100': '☶',  # 艮 (Mountain)
    '011': '☴',  # 巽 (Wind)
    '101': '☲',  # 离 (Fire)
    '110': '☱',  # 兑 (Lake)
}

def binary_to_symbol(binary_code):
    """将6位二进制转为上下卦Unicode符号组合"""
    b = binary_code.zfill(6)
    upper = b[:3]  # 上卦
    lower = b[3:]  # 下卦
    upper_sym = TRIGRAM_SYMBOLS.get(upper, '?')
    lower_sym = TRIGRAM_SYMBOLS.get(lower, '?')
    return f"{upper_sym}{lower_sym}"  # 上卦在前，下卦在后

# ─────────────────────────────────────────────
# 4. 解析单个 .text 文件
# ─────────────────────────────────────────────
def parse_text_file(filepath, hex_name):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = [l.strip() for l in content.split('\n') if l.strip()]

    # ── 1. 卦象自身信息 ──
    nature = ""
    first_line = lines[0] if lines else ""
    if '象曰：' in first_line:
        # 优先取"大象"象曰
        m = re.search(r'象曰：([^。]+)', first_line)
        if m:
            nature = m.group(1).strip()
    if not nature:
        nature = first_line[:60]

    # ── 2. 逐爻解析 ──
    # 爻标记列表（按顺序代表爻位 1-6）
    YAO_LABELS = ['初六', '初九', '六二', '九二', '六三', '九三',
                  '六四', '九四', '六五', '九五', '上六', '上九']

    def label_to_pos(label):
        m = {'初': 1, '二': 2, '三': 3, '四': 4, '五': 5, '上': 6}
        for k, v in m.items():
            if k in label:
                return v
        return None

    # 用正则切分含"爻辞"的段落（每个爻段以 "XXX爻辞" 开头）
    yao_block_pattern = re.compile(
        r'(初[六九]|[六九][二三四五]|上[六九])爻辞(.+?)(?=(?:初[六九]|[六九][二三四五]|上[六九])爻辞|$)',
        re.DOTALL
    )

    yao_list = []   # 按爻位顺序的 dict 列表
    yao_rules = {}  # {爻位str: 变卦id}

    for block_match in yao_block_pattern.finditer(content):
        yao_label = block_match.group(1)
        block_text = block_match.group(2)
        yao_pos = label_to_pos(yao_label)
        if yao_pos is None:
            continue

        # ── 2-a. 爻辞原文 & 象曰 ──
        yao_ci = ""
        xiang_yue = ""
        
        # 寻找爻辞原文：从爻号（如九五）后到“象曰”前的内容
        # 我们用 search 避免 re.match 对起始位置的严格要求
        # 匹配逻辑：爻号 + [。．\s]* + (核心爻辞) + 象曰
        ci_search = re.search(
            rf'{yao_label}[。．\s]*(.*?)象曰',
            block_text,
            re.DOTALL
        )
        if ci_search:
            yao_ci = ci_search.group(1).strip().strip('。．').strip()
            
            # 寻找象曰：从“象曰：”后到下一个句号或白话文解释前
            xiang_search = re.search(
                r'象曰[：:](.*?)(?:[。．]|白话文解释)',
                block_text,
                re.DOTALL
            )
            if xiang_search:
                xiang_yue = xiang_search.group(1).strip()
        else:
            # 备选方案：如果没找到“象曰”，尝试抓取第一个句号前的内容
            fb_search = re.search(rf'{yao_label}[。．\s]*(.*?)[。．]', block_text)
            if fb_search:
                yao_ci = fb_search.group(1).strip()

        # ── 2-b. 白话文解释 ──
        vernacular = ""
        m_bh = re.search(r'白话文解释(?:初[六九]|[六九][二三四五]|上[六九])[：:](.+?)(?:《象辞》|北宋|台湾国学|$)', block_text, re.DOTALL)
        if m_bh:
            vernacular = m_bh.group(1).strip().replace('\n', '')[:120]

        # ── 2-c. 邵雍解（吉凶星级 + 策略摘要）──
        shaoyong_rating = ""   # 吉 / 平 / 凶
        shaoyong_hint = ""
        m_sy = re.search(r'北宋易学家邵雍解(吉|平|凶)[：:](.+?)(?:台湾国学|做官|$)', block_text, re.DOTALL)
        if m_sy:
            shaoyong_rating = m_sy.group(1)
            shaoyong_hint = m_sy.group(2).strip().replace('\n', '')[:100]

        # ── 2-d. 傅佩荣解（时运/财运/身体 → 游戏三才对应）──
        fu_shiyun = ""    # 时运 → 对应游戏"实力/天"
        fu_caiyun = ""    # 财运 → 对应游戏"资财/地"
        fu_shenti = ""    # 身体(运势) → 对应游戏"民心/人"
        m_fu = re.search(r'傅佩荣解时运：(.+?)财运：(.+?)(?:家宅：.+?)?身体：(.+?)(?:\n|$)', block_text)
        if m_fu:
            fu_shiyun = m_fu.group(1).strip().rstrip('。')
            fu_caiyun = m_fu.group(2).strip().rstrip('。')
            fu_shenti = m_fu.group(3).strip().rstrip('。')

        # ── 2-e. 变卦目标 ──
        m_chg = re.search(r'变卦.{0,15}变得周易第(\d+)卦', block_text)
        target_id = int(m_chg.group(1)) if m_chg else None
        if target_id:
            yao_rules[str(yao_pos)] = target_id

        yao_list.append({
            "position": yao_pos,
            "label": yao_label,
            "yao_ci": yao_ci,           # 爻辞原文，如"潜龙勿用"
            "xiang_yue": xiang_yue,     # 象曰，如"潜龙勿用，阳在下也"
            "vernacular": vernacular,   # 白话文翻译
            "rating": shaoyong_rating,  # 吉/平/凶（邵雍）
            "strategy_hint": shaoyong_hint,    # 邵雍策略简述
            "stat_strength": fu_shiyun,        # 时运 → 天/实力
            "stat_treasury": fu_caiyun,        # 财运 → 地/资财
            "stat_morale": fu_shenti,          # 身体 → 人/民心
            "changed_to": target_id            # 变爻后的目标卦id
        })

    # 按 position 排序
    yao_list.sort(key=lambda x: x['position'])

    # 补全 yao_rules（若未解析到则 fallback 为 0 → 不变）
    for i in range(1, 7):
        if str(i) not in yao_rules:
            yao_rules[str(i)] = 0

    # philosophy_hints 保持向后兼容：取爻辞原文列表
    philosophy_hints = [y['yao_ci'] for y in yao_list if y['yao_ci']]

    return nature, philosophy_hints, yao_rules, yao_list

def label_to_position(label):
    """将爻标签转为爻位数字 1-6"""
    map_ = {
        '初': 1, '二': 2, '三': 3, '四': 4, '五': 5, '上': 6
    }
    for key, val in map_.items():
        if key in label:
            return val
    return None

# ─────────────────────────────────────────────
# 5. 主程序
# ─────────────────────────────────────────────
def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    data_dir = script_dir  # .text 文件在同目录
    output_path = os.path.join(script_dir, '..', 'game', 'hexagrams.json')
    
    hexagrams = []
    
    for binary_code, hex_name in BINARY_TO_NAME.items():
        # 补全6位（有一个 '10111' 是5位的，可能缺了前导0）
        filename = binary_code + '.text'
        filepath = os.path.join(data_dir, filename)
        
        if not os.path.exists(filepath):
            print(f"警告: 文件不存在 {filename}，跳过 {hex_name}")
            continue
        
        hex_id = NAME_TO_ID.get(hex_name)
        if hex_id is None:
            print(f"警告: 找不到 {hex_name} 的序号，跳过")
            continue
        
        symbol = binary_to_symbol(binary_code)
        nature, philosophy_hints, yao_rules, yao_list = parse_text_file(filepath, hex_name)
        
        # fallback: yao_rules 中若有 0，补为自身id（无变化）
        for i in range(1, 7):
            if str(i) not in yao_rules or yao_rules[str(i)] == 0:
                yao_rules[str(i)] = hex_id
        
        hexagrams.append({
            "id": hex_id,
            "name_zh": hex_name,
            "name": hex_name,
            "symbol": symbol,
            "binary": binary_code.zfill(6),
            "nature": nature,
            "yao_rules": yao_rules,          # {位: 目标卦id} 供 RuleEngine 快速查
            "philosophy_hints": philosophy_hints,  # 爻辞原文列表（向后兼容）
            "yao_lines": yao_list            # 完整六爻详情，供 Agent prompt 调用
        })
    
    # 按 King Wen 顺序排序
    hexagrams.sort(key=lambda x: x['id'])
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(hexagrams, f, ensure_ascii=False, indent=2)
    
    print(f"[OK] Generated {len(hexagrams)} hexagrams -> {os.path.abspath(output_path)}")
    
    # 统计完整性
    missing_yao = [h for h in hexagrams if len(h['yao_lines']) < 6]
    no_ci = sum(1 for h in hexagrams for y in h['yao_lines'] if not y['yao_ci'])
    print(f"[OK] yao_lines parsed: {sum(len(h['yao_lines']) for h in hexagrams)} total lines across 64 hexagrams")
    if missing_yao:
        print(f"[WARN] {len(missing_yao)} hexagrams have <6 yao_lines: {[h['name_zh'] for h in missing_yao]}")
    if no_ci:
        print(f"[WARN] {no_ci} yao entries missing yao_ci text")

if __name__ == '__main__':
    main()
