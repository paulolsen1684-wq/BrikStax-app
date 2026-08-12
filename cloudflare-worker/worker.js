var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// node_modules/qrcode-generator/dist/qrcode.mjs
var qrcode = /* @__PURE__ */ __name(function(typeNumber, errorCorrectionLevel) {
  const PAD0 = 236;
  const PAD1 = 17;
  let _typeNumber = typeNumber;
  const _errorCorrectionLevel = QRErrorCorrectionLevel[errorCorrectionLevel];
  let _modules = null;
  let _moduleCount = 0;
  let _dataCache = null;
  const _dataList = [];
  const _this = {};
  const makeImpl = /* @__PURE__ */ __name(function(test, maskPattern) {
    _moduleCount = _typeNumber * 4 + 17;
    _modules = (function(moduleCount) {
      const modules = new Array(moduleCount);
      for (let row = 0; row < moduleCount; row += 1) {
        modules[row] = new Array(moduleCount);
        for (let col = 0; col < moduleCount; col += 1) {
          modules[row][col] = null;
        }
      }
      return modules;
    })(_moduleCount);
    setupPositionProbePattern(0, 0);
    setupPositionProbePattern(_moduleCount - 7, 0);
    setupPositionProbePattern(0, _moduleCount - 7);
    setupPositionAdjustPattern();
    setupTimingPattern();
    setupTypeInfo(test, maskPattern);
    if (_typeNumber >= 7) {
      setupTypeNumber(test);
    }
    if (_dataCache == null) {
      _dataCache = createData(_typeNumber, _errorCorrectionLevel, _dataList);
    }
    mapData(_dataCache, maskPattern);
  }, "makeImpl");
  const setupPositionProbePattern = /* @__PURE__ */ __name(function(row, col) {
    for (let r = -1; r <= 7; r += 1) {
      if (row + r <= -1 || _moduleCount <= row + r) continue;
      for (let c = -1; c <= 7; c += 1) {
        if (col + c <= -1 || _moduleCount <= col + c) continue;
        if (0 <= r && r <= 6 && (c == 0 || c == 6) || 0 <= c && c <= 6 && (r == 0 || r == 6) || 2 <= r && r <= 4 && 2 <= c && c <= 4) {
          _modules[row + r][col + c] = true;
        } else {
          _modules[row + r][col + c] = false;
        }
      }
    }
  }, "setupPositionProbePattern");
  const getBestMaskPattern = /* @__PURE__ */ __name(function() {
    let minLostPoint = 0;
    let pattern = 0;
    for (let i = 0; i < 8; i += 1) {
      makeImpl(true, i);
      const lostPoint = QRUtil.getLostPoint(_this);
      if (i == 0 || minLostPoint > lostPoint) {
        minLostPoint = lostPoint;
        pattern = i;
      }
    }
    return pattern;
  }, "getBestMaskPattern");
  const setupTimingPattern = /* @__PURE__ */ __name(function() {
    for (let r = 8; r < _moduleCount - 8; r += 1) {
      if (_modules[r][6] != null) {
        continue;
      }
      _modules[r][6] = r % 2 == 0;
    }
    for (let c = 8; c < _moduleCount - 8; c += 1) {
      if (_modules[6][c] != null) {
        continue;
      }
      _modules[6][c] = c % 2 == 0;
    }
  }, "setupTimingPattern");
  const setupPositionAdjustPattern = /* @__PURE__ */ __name(function() {
    const pos = QRUtil.getPatternPosition(_typeNumber);
    for (let i = 0; i < pos.length; i += 1) {
      for (let j = 0; j < pos.length; j += 1) {
        const row = pos[i];
        const col = pos[j];
        if (_modules[row][col] != null) {
          continue;
        }
        for (let r = -2; r <= 2; r += 1) {
          for (let c = -2; c <= 2; c += 1) {
            if (r == -2 || r == 2 || c == -2 || c == 2 || r == 0 && c == 0) {
              _modules[row + r][col + c] = true;
            } else {
              _modules[row + r][col + c] = false;
            }
          }
        }
      }
    }
  }, "setupPositionAdjustPattern");
  const setupTypeNumber = /* @__PURE__ */ __name(function(test) {
    const bits = QRUtil.getBCHTypeNumber(_typeNumber);
    for (let i = 0; i < 18; i += 1) {
      const mod = !test && (bits >> i & 1) == 1;
      _modules[Math.floor(i / 3)][i % 3 + _moduleCount - 8 - 3] = mod;
    }
    for (let i = 0; i < 18; i += 1) {
      const mod = !test && (bits >> i & 1) == 1;
      _modules[i % 3 + _moduleCount - 8 - 3][Math.floor(i / 3)] = mod;
    }
  }, "setupTypeNumber");
  const setupTypeInfo = /* @__PURE__ */ __name(function(test, maskPattern) {
    const data = _errorCorrectionLevel << 3 | maskPattern;
    const bits = QRUtil.getBCHTypeInfo(data);
    for (let i = 0; i < 15; i += 1) {
      const mod = !test && (bits >> i & 1) == 1;
      if (i < 6) {
        _modules[i][8] = mod;
      } else if (i < 8) {
        _modules[i + 1][8] = mod;
      } else {
        _modules[_moduleCount - 15 + i][8] = mod;
      }
    }
    for (let i = 0; i < 15; i += 1) {
      const mod = !test && (bits >> i & 1) == 1;
      if (i < 8) {
        _modules[8][_moduleCount - i - 1] = mod;
      } else if (i < 9) {
        _modules[8][15 - i - 1 + 1] = mod;
      } else {
        _modules[8][15 - i - 1] = mod;
      }
    }
    _modules[_moduleCount - 8][8] = !test;
  }, "setupTypeInfo");
  const mapData = /* @__PURE__ */ __name(function(data, maskPattern) {
    let inc = -1;
    let row = _moduleCount - 1;
    let bitIndex = 7;
    let byteIndex = 0;
    const maskFunc = QRUtil.getMaskFunction(maskPattern);
    for (let col = _moduleCount - 1; col > 0; col -= 2) {
      if (col == 6) col -= 1;
      while (true) {
        for (let c = 0; c < 2; c += 1) {
          if (_modules[row][col - c] == null) {
            let dark = false;
            if (byteIndex < data.length) {
              dark = (data[byteIndex] >>> bitIndex & 1) == 1;
            }
            const mask = maskFunc(row, col - c);
            if (mask) {
              dark = !dark;
            }
            _modules[row][col - c] = dark;
            bitIndex -= 1;
            if (bitIndex == -1) {
              byteIndex += 1;
              bitIndex = 7;
            }
          }
        }
        row += inc;
        if (row < 0 || _moduleCount <= row) {
          row -= inc;
          inc = -inc;
          break;
        }
      }
    }
  }, "mapData");
  const createBytes = /* @__PURE__ */ __name(function(buffer, rsBlocks) {
    let offset = 0;
    let maxDcCount = 0;
    let maxEcCount = 0;
    const dcdata = new Array(rsBlocks.length);
    const ecdata = new Array(rsBlocks.length);
    for (let r = 0; r < rsBlocks.length; r += 1) {
      const dcCount = rsBlocks[r].dataCount;
      const ecCount = rsBlocks[r].totalCount - dcCount;
      maxDcCount = Math.max(maxDcCount, dcCount);
      maxEcCount = Math.max(maxEcCount, ecCount);
      dcdata[r] = new Array(dcCount);
      for (let i = 0; i < dcdata[r].length; i += 1) {
        dcdata[r][i] = 255 & buffer.getBuffer()[i + offset];
      }
      offset += dcCount;
      const rsPoly = QRUtil.getErrorCorrectPolynomial(ecCount);
      const rawPoly = qrPolynomial(dcdata[r], rsPoly.getLength() - 1);
      const modPoly = rawPoly.mod(rsPoly);
      ecdata[r] = new Array(rsPoly.getLength() - 1);
      for (let i = 0; i < ecdata[r].length; i += 1) {
        const modIndex = i + modPoly.getLength() - ecdata[r].length;
        ecdata[r][i] = modIndex >= 0 ? modPoly.getAt(modIndex) : 0;
      }
    }
    let totalCodeCount = 0;
    for (let i = 0; i < rsBlocks.length; i += 1) {
      totalCodeCount += rsBlocks[i].totalCount;
    }
    const data = new Array(totalCodeCount);
    let index = 0;
    for (let i = 0; i < maxDcCount; i += 1) {
      for (let r = 0; r < rsBlocks.length; r += 1) {
        if (i < dcdata[r].length) {
          data[index] = dcdata[r][i];
          index += 1;
        }
      }
    }
    for (let i = 0; i < maxEcCount; i += 1) {
      for (let r = 0; r < rsBlocks.length; r += 1) {
        if (i < ecdata[r].length) {
          data[index] = ecdata[r][i];
          index += 1;
        }
      }
    }
    return data;
  }, "createBytes");
  const createData = /* @__PURE__ */ __name(function(typeNumber2, errorCorrectionLevel2, dataList) {
    const rsBlocks = QRRSBlock.getRSBlocks(typeNumber2, errorCorrectionLevel2);
    const buffer = qrBitBuffer();
    for (let i = 0; i < dataList.length; i += 1) {
      const data = dataList[i];
      buffer.put(data.getMode(), 4);
      buffer.put(data.getLength(), QRUtil.getLengthInBits(data.getMode(), typeNumber2));
      data.write(buffer);
    }
    let totalDataCount = 0;
    for (let i = 0; i < rsBlocks.length; i += 1) {
      totalDataCount += rsBlocks[i].dataCount;
    }
    if (buffer.getLengthInBits() > totalDataCount * 8) {
      throw "code length overflow. (" + buffer.getLengthInBits() + ">" + totalDataCount * 8 + ")";
    }
    if (buffer.getLengthInBits() + 4 <= totalDataCount * 8) {
      buffer.put(0, 4);
    }
    while (buffer.getLengthInBits() % 8 != 0) {
      buffer.putBit(false);
    }
    while (true) {
      if (buffer.getLengthInBits() >= totalDataCount * 8) {
        break;
      }
      buffer.put(PAD0, 8);
      if (buffer.getLengthInBits() >= totalDataCount * 8) {
        break;
      }
      buffer.put(PAD1, 8);
    }
    return createBytes(buffer, rsBlocks);
  }, "createData");
  _this.addData = function(data, mode) {
    mode = mode || "Byte";
    let newData = null;
    switch (mode) {
      case "Numeric":
        newData = qrNumber(data);
        break;
      case "Alphanumeric":
        newData = qrAlphaNum(data);
        break;
      case "Byte":
        newData = qr8BitByte(data);
        break;
      case "Kanji":
        newData = qrKanji(data);
        break;
      default:
        throw "mode:" + mode;
    }
    _dataList.push(newData);
    _dataCache = null;
  };
  _this.isDark = function(row, col) {
    if (row < 0 || _moduleCount <= row || col < 0 || _moduleCount <= col) {
      throw row + "," + col;
    }
    return _modules[row][col];
  };
  _this.getModuleCount = function() {
    return _moduleCount;
  };
  _this.make = function() {
    if (_typeNumber < 1) {
      let typeNumber2 = 1;
      for (; typeNumber2 < 40; typeNumber2++) {
        const rsBlocks = QRRSBlock.getRSBlocks(typeNumber2, _errorCorrectionLevel);
        const buffer = qrBitBuffer();
        for (let i = 0; i < _dataList.length; i++) {
          const data = _dataList[i];
          buffer.put(data.getMode(), 4);
          buffer.put(data.getLength(), QRUtil.getLengthInBits(data.getMode(), typeNumber2));
          data.write(buffer);
        }
        let totalDataCount = 0;
        for (let i = 0; i < rsBlocks.length; i++) {
          totalDataCount += rsBlocks[i].dataCount;
        }
        if (buffer.getLengthInBits() <= totalDataCount * 8) {
          break;
        }
      }
      _typeNumber = typeNumber2;
    }
    makeImpl(false, getBestMaskPattern());
  };
  _this.createTableTag = function(cellSize, margin) {
    cellSize = cellSize || 2;
    margin = typeof margin == "undefined" ? cellSize * 4 : margin;
    let qrHtml = "";
    qrHtml += '<table style="';
    qrHtml += " border-width: 0px; border-style: none;";
    qrHtml += " border-collapse: collapse;";
    qrHtml += " padding: 0px; margin: " + margin + "px;";
    qrHtml += '">';
    qrHtml += "<tbody>";
    for (let r = 0; r < _this.getModuleCount(); r += 1) {
      qrHtml += "<tr>";
      for (let c = 0; c < _this.getModuleCount(); c += 1) {
        qrHtml += '<td style="';
        qrHtml += " border-width: 0px; border-style: none;";
        qrHtml += " border-collapse: collapse;";
        qrHtml += " padding: 0px; margin: 0px;";
        qrHtml += " width: " + cellSize + "px;";
        qrHtml += " height: " + cellSize + "px;";
        qrHtml += " background-color: ";
        qrHtml += _this.isDark(r, c) ? "#000000" : "#ffffff";
        qrHtml += ";";
        qrHtml += '"/>';
      }
      qrHtml += "</tr>";
    }
    qrHtml += "</tbody>";
    qrHtml += "</table>";
    return qrHtml;
  };
  _this.createSvgTag = function(cellSize, margin, alt, title) {
    let opts = {};
    if (typeof arguments[0] == "object") {
      opts = arguments[0];
      cellSize = opts.cellSize;
      margin = opts.margin;
      alt = opts.alt;
      title = opts.title;
    }
    cellSize = cellSize || 2;
    margin = typeof margin == "undefined" ? cellSize * 4 : margin;
    alt = typeof alt === "string" ? { text: alt } : alt || {};
    alt.text = alt.text || null;
    alt.id = alt.text ? alt.id || "qrcode-description" : null;
    title = typeof title === "string" ? { text: title } : title || {};
    title.text = title.text || null;
    title.id = title.text ? title.id || "qrcode-title" : null;
    const size = _this.getModuleCount() * cellSize + margin * 2;
    let c, mc, r, mr, qrSvg = "", rect;
    rect = "l" + cellSize + ",0 0," + cellSize + " -" + cellSize + ",0 0,-" + cellSize + "z ";
    qrSvg += '<svg version="1.1" xmlns="http://www.w3.org/2000/svg"';
    qrSvg += !opts.scalable ? ' width="' + size + 'px" height="' + size + 'px"' : "";
    qrSvg += ' viewBox="0 0 ' + size + " " + size + '" ';
    qrSvg += ' preserveAspectRatio="xMinYMin meet"';
    qrSvg += title.text || alt.text ? ' role="img" aria-labelledby="' + escapeXml([title.id, alt.id].join(" ").trim()) + '"' : "";
    qrSvg += ">";
    qrSvg += title.text ? '<title id="' + escapeXml(title.id) + '">' + escapeXml(title.text) + "</title>" : "";
    qrSvg += alt.text ? '<description id="' + escapeXml(alt.id) + '">' + escapeXml(alt.text) + "</description>" : "";
    qrSvg += '<rect width="100%" height="100%" fill="white" cx="0" cy="0"/>';
    qrSvg += '<path d="';
    for (r = 0; r < _this.getModuleCount(); r += 1) {
      mr = r * cellSize + margin;
      for (c = 0; c < _this.getModuleCount(); c += 1) {
        if (_this.isDark(r, c)) {
          mc = c * cellSize + margin;
          qrSvg += "M" + mc + "," + mr + rect;
        }
      }
    }
    qrSvg += '" stroke="transparent" fill="black"/>';
    qrSvg += "</svg>";
    return qrSvg;
  };
  _this.createDataURL = function(cellSize, margin) {
    cellSize = cellSize || 2;
    margin = typeof margin == "undefined" ? cellSize * 4 : margin;
    const size = _this.getModuleCount() * cellSize + margin * 2;
    const min = margin;
    const max = size - margin;
    return createDataURL(size, size, function(x, y) {
      if (min <= x && x < max && min <= y && y < max) {
        const c = Math.floor((x - min) / cellSize);
        const r = Math.floor((y - min) / cellSize);
        return _this.isDark(r, c) ? 0 : 1;
      } else {
        return 1;
      }
    });
  };
  _this.createImgTag = function(cellSize, margin, alt) {
    cellSize = cellSize || 2;
    margin = typeof margin == "undefined" ? cellSize * 4 : margin;
    const size = _this.getModuleCount() * cellSize + margin * 2;
    let img = "";
    img += "<img";
    img += ' src="';
    img += _this.createDataURL(cellSize, margin);
    img += '"';
    img += ' width="';
    img += size;
    img += '"';
    img += ' height="';
    img += size;
    img += '"';
    if (alt) {
      img += ' alt="';
      img += escapeXml(alt);
      img += '"';
    }
    img += "/>";
    return img;
  };
  const escapeXml = /* @__PURE__ */ __name(function(s) {
    let escaped = "";
    for (let i = 0; i < s.length; i += 1) {
      const c = s.charAt(i);
      switch (c) {
        case "<":
          escaped += "&lt;";
          break;
        case ">":
          escaped += "&gt;";
          break;
        case "&":
          escaped += "&amp;";
          break;
        case '"':
          escaped += "&quot;";
          break;
        default:
          escaped += c;
          break;
      }
    }
    return escaped;
  }, "escapeXml");
  const _createHalfASCII = /* @__PURE__ */ __name(function(margin) {
    const cellSize = 1;
    margin = typeof margin == "undefined" ? cellSize * 2 : margin;
    const size = _this.getModuleCount() * cellSize + margin * 2;
    const min = margin;
    const max = size - margin;
    let y, x, r1, r2, p;
    const blocks = {
      "\u2588\u2588": "\u2588",
      "\u2588 ": "\u2580",
      " \u2588": "\u2584",
      "  ": " "
    };
    const blocksLastLineNoMargin = {
      "\u2588\u2588": "\u2580",
      "\u2588 ": "\u2580",
      " \u2588": " ",
      "  ": " "
    };
    let ascii = "";
    for (y = 0; y < size; y += 2) {
      r1 = Math.floor((y - min) / cellSize);
      r2 = Math.floor((y + 1 - min) / cellSize);
      for (x = 0; x < size; x += 1) {
        p = "\u2588";
        if (min <= x && x < max && min <= y && y < max && _this.isDark(r1, Math.floor((x - min) / cellSize))) {
          p = " ";
        }
        if (min <= x && x < max && min <= y + 1 && y + 1 < max && _this.isDark(r2, Math.floor((x - min) / cellSize))) {
          p += " ";
        } else {
          p += "\u2588";
        }
        ascii += margin < 1 && y + 1 >= max ? blocksLastLineNoMargin[p] : blocks[p];
      }
      ascii += "\n";
    }
    if (size % 2 && margin > 0) {
      return ascii.substring(0, ascii.length - size - 1) + Array(size + 1).join("\u2580");
    }
    return ascii.substring(0, ascii.length - 1);
  }, "_createHalfASCII");
  _this.createASCII = function(cellSize, margin) {
    cellSize = cellSize || 1;
    if (cellSize < 2) {
      return _createHalfASCII(margin);
    }
    cellSize -= 1;
    margin = typeof margin == "undefined" ? cellSize * 2 : margin;
    const size = _this.getModuleCount() * cellSize + margin * 2;
    const min = margin;
    const max = size - margin;
    let y, x, r, p;
    const white = Array(cellSize + 1).join("\u2588\u2588");
    const black = Array(cellSize + 1).join("  ");
    let ascii = "";
    let line = "";
    for (y = 0; y < size; y += 1) {
      r = Math.floor((y - min) / cellSize);
      line = "";
      for (x = 0; x < size; x += 1) {
        p = 1;
        if (min <= x && x < max && min <= y && y < max && _this.isDark(r, Math.floor((x - min) / cellSize))) {
          p = 0;
        }
        line += p ? white : black;
      }
      for (r = 0; r < cellSize; r += 1) {
        ascii += line + "\n";
      }
    }
    return ascii.substring(0, ascii.length - 1);
  };
  _this.renderTo2dContext = function(context, cellSize) {
    cellSize = cellSize || 2;
    const length = _this.getModuleCount();
    for (let row = 0; row < length; row++) {
      for (let col = 0; col < length; col++) {
        context.fillStyle = _this.isDark(row, col) ? "black" : "white";
        context.fillRect(col * cellSize, row * cellSize, cellSize, cellSize);
      }
    }
  };
  return _this;
}, "qrcode");
qrcode.stringToBytes = function(s) {
  const bytes = [];
  for (let i = 0; i < s.length; i += 1) {
    const c = s.charCodeAt(i);
    bytes.push(c & 255);
  }
  return bytes;
};
qrcode.createStringToBytes = function(unicodeData, numChars) {
  const unicodeMap = (function() {
    const bin = base64DecodeInputStream(unicodeData);
    const read = /* @__PURE__ */ __name(function() {
      const b = bin.read();
      if (b == -1) throw "eof";
      return b;
    }, "read");
    let count = 0;
    const unicodeMap2 = {};
    while (true) {
      const b0 = bin.read();
      if (b0 == -1) break;
      const b1 = read();
      const b2 = read();
      const b3 = read();
      const k = String.fromCharCode(b0 << 8 | b1);
      const v = b2 << 8 | b3;
      unicodeMap2[k] = v;
      count += 1;
    }
    if (count != numChars) {
      throw count + " != " + numChars;
    }
    return unicodeMap2;
  })();
  const unknownChar = "?".charCodeAt(0);
  return function(s) {
    const bytes = [];
    for (let i = 0; i < s.length; i += 1) {
      const c = s.charCodeAt(i);
      if (c < 128) {
        bytes.push(c);
      } else {
        const b = unicodeMap[s.charAt(i)];
        if (typeof b == "number") {
          if ((b & 255) == b) {
            bytes.push(b);
          } else {
            bytes.push(b >>> 8);
            bytes.push(b & 255);
          }
        } else {
          bytes.push(unknownChar);
        }
      }
    }
    return bytes;
  };
};
var QRMode = {
  MODE_NUMBER: 1 << 0,
  MODE_ALPHA_NUM: 1 << 1,
  MODE_8BIT_BYTE: 1 << 2,
  MODE_KANJI: 1 << 3
};
var QRErrorCorrectionLevel = {
  L: 1,
  M: 0,
  Q: 3,
  H: 2
};
var QRMaskPattern = {
  PATTERN000: 0,
  PATTERN001: 1,
  PATTERN010: 2,
  PATTERN011: 3,
  PATTERN100: 4,
  PATTERN101: 5,
  PATTERN110: 6,
  PATTERN111: 7
};
var QRUtil = (function() {
  const PATTERN_POSITION_TABLE = [
    [],
    [6, 18],
    [6, 22],
    [6, 26],
    [6, 30],
    [6, 34],
    [6, 22, 38],
    [6, 24, 42],
    [6, 26, 46],
    [6, 28, 50],
    [6, 30, 54],
    [6, 32, 58],
    [6, 34, 62],
    [6, 26, 46, 66],
    [6, 26, 48, 70],
    [6, 26, 50, 74],
    [6, 30, 54, 78],
    [6, 30, 56, 82],
    [6, 30, 58, 86],
    [6, 34, 62, 90],
    [6, 28, 50, 72, 94],
    [6, 26, 50, 74, 98],
    [6, 30, 54, 78, 102],
    [6, 28, 54, 80, 106],
    [6, 32, 58, 84, 110],
    [6, 30, 58, 86, 114],
    [6, 34, 62, 90, 118],
    [6, 26, 50, 74, 98, 122],
    [6, 30, 54, 78, 102, 126],
    [6, 26, 52, 78, 104, 130],
    [6, 30, 56, 82, 108, 134],
    [6, 34, 60, 86, 112, 138],
    [6, 30, 58, 86, 114, 142],
    [6, 34, 62, 90, 118, 146],
    [6, 30, 54, 78, 102, 126, 150],
    [6, 24, 50, 76, 102, 128, 154],
    [6, 28, 54, 80, 106, 132, 158],
    [6, 32, 58, 84, 110, 136, 162],
    [6, 26, 54, 82, 110, 138, 166],
    [6, 30, 58, 86, 114, 142, 170]
  ];
  const G15 = 1 << 10 | 1 << 8 | 1 << 5 | 1 << 4 | 1 << 2 | 1 << 1 | 1 << 0;
  const G18 = 1 << 12 | 1 << 11 | 1 << 10 | 1 << 9 | 1 << 8 | 1 << 5 | 1 << 2 | 1 << 0;
  const G15_MASK = 1 << 14 | 1 << 12 | 1 << 10 | 1 << 4 | 1 << 1;
  const _this = {};
  const getBCHDigit = /* @__PURE__ */ __name(function(data) {
    let digit = 0;
    while (data != 0) {
      digit += 1;
      data >>>= 1;
    }
    return digit;
  }, "getBCHDigit");
  _this.getBCHTypeInfo = function(data) {
    let d = data << 10;
    while (getBCHDigit(d) - getBCHDigit(G15) >= 0) {
      d ^= G15 << getBCHDigit(d) - getBCHDigit(G15);
    }
    return (data << 10 | d) ^ G15_MASK;
  };
  _this.getBCHTypeNumber = function(data) {
    let d = data << 12;
    while (getBCHDigit(d) - getBCHDigit(G18) >= 0) {
      d ^= G18 << getBCHDigit(d) - getBCHDigit(G18);
    }
    return data << 12 | d;
  };
  _this.getPatternPosition = function(typeNumber) {
    return PATTERN_POSITION_TABLE[typeNumber - 1];
  };
  _this.getMaskFunction = function(maskPattern) {
    switch (maskPattern) {
      case QRMaskPattern.PATTERN000:
        return function(i, j) {
          return (i + j) % 2 == 0;
        };
      case QRMaskPattern.PATTERN001:
        return function(i, j) {
          return i % 2 == 0;
        };
      case QRMaskPattern.PATTERN010:
        return function(i, j) {
          return j % 3 == 0;
        };
      case QRMaskPattern.PATTERN011:
        return function(i, j) {
          return (i + j) % 3 == 0;
        };
      case QRMaskPattern.PATTERN100:
        return function(i, j) {
          return (Math.floor(i / 2) + Math.floor(j / 3)) % 2 == 0;
        };
      case QRMaskPattern.PATTERN101:
        return function(i, j) {
          return i * j % 2 + i * j % 3 == 0;
        };
      case QRMaskPattern.PATTERN110:
        return function(i, j) {
          return (i * j % 2 + i * j % 3) % 2 == 0;
        };
      case QRMaskPattern.PATTERN111:
        return function(i, j) {
          return (i * j % 3 + (i + j) % 2) % 2 == 0;
        };
      default:
        throw "bad maskPattern:" + maskPattern;
    }
  };
  _this.getErrorCorrectPolynomial = function(errorCorrectLength) {
    let a = qrPolynomial([1], 0);
    for (let i = 0; i < errorCorrectLength; i += 1) {
      a = a.multiply(qrPolynomial([1, QRMath.gexp(i)], 0));
    }
    return a;
  };
  _this.getLengthInBits = function(mode, type) {
    if (1 <= type && type < 10) {
      switch (mode) {
        case QRMode.MODE_NUMBER:
          return 10;
        case QRMode.MODE_ALPHA_NUM:
          return 9;
        case QRMode.MODE_8BIT_BYTE:
          return 8;
        case QRMode.MODE_KANJI:
          return 8;
        default:
          throw "mode:" + mode;
      }
    } else if (type < 27) {
      switch (mode) {
        case QRMode.MODE_NUMBER:
          return 12;
        case QRMode.MODE_ALPHA_NUM:
          return 11;
        case QRMode.MODE_8BIT_BYTE:
          return 16;
        case QRMode.MODE_KANJI:
          return 10;
        default:
          throw "mode:" + mode;
      }
    } else if (type < 41) {
      switch (mode) {
        case QRMode.MODE_NUMBER:
          return 14;
        case QRMode.MODE_ALPHA_NUM:
          return 13;
        case QRMode.MODE_8BIT_BYTE:
          return 16;
        case QRMode.MODE_KANJI:
          return 12;
        default:
          throw "mode:" + mode;
      }
    } else {
      throw "type:" + type;
    }
  };
  _this.getLostPoint = function(qrcode2) {
    const moduleCount = qrcode2.getModuleCount();
    let lostPoint = 0;
    for (let row = 0; row < moduleCount; row += 1) {
      for (let col = 0; col < moduleCount; col += 1) {
        let sameCount = 0;
        const dark = qrcode2.isDark(row, col);
        for (let r = -1; r <= 1; r += 1) {
          if (row + r < 0 || moduleCount <= row + r) {
            continue;
          }
          for (let c = -1; c <= 1; c += 1) {
            if (col + c < 0 || moduleCount <= col + c) {
              continue;
            }
            if (r == 0 && c == 0) {
              continue;
            }
            if (dark == qrcode2.isDark(row + r, col + c)) {
              sameCount += 1;
            }
          }
        }
        if (sameCount > 5) {
          lostPoint += 3 + sameCount - 5;
        }
      }
    }
    ;
    for (let row = 0; row < moduleCount - 1; row += 1) {
      for (let col = 0; col < moduleCount - 1; col += 1) {
        let count = 0;
        if (qrcode2.isDark(row, col)) count += 1;
        if (qrcode2.isDark(row + 1, col)) count += 1;
        if (qrcode2.isDark(row, col + 1)) count += 1;
        if (qrcode2.isDark(row + 1, col + 1)) count += 1;
        if (count == 0 || count == 4) {
          lostPoint += 3;
        }
      }
    }
    for (let row = 0; row < moduleCount; row += 1) {
      for (let col = 0; col < moduleCount - 6; col += 1) {
        if (qrcode2.isDark(row, col) && !qrcode2.isDark(row, col + 1) && qrcode2.isDark(row, col + 2) && qrcode2.isDark(row, col + 3) && qrcode2.isDark(row, col + 4) && !qrcode2.isDark(row, col + 5) && qrcode2.isDark(row, col + 6)) {
          lostPoint += 40;
        }
      }
    }
    for (let col = 0; col < moduleCount; col += 1) {
      for (let row = 0; row < moduleCount - 6; row += 1) {
        if (qrcode2.isDark(row, col) && !qrcode2.isDark(row + 1, col) && qrcode2.isDark(row + 2, col) && qrcode2.isDark(row + 3, col) && qrcode2.isDark(row + 4, col) && !qrcode2.isDark(row + 5, col) && qrcode2.isDark(row + 6, col)) {
          lostPoint += 40;
        }
      }
    }
    let darkCount = 0;
    for (let col = 0; col < moduleCount; col += 1) {
      for (let row = 0; row < moduleCount; row += 1) {
        if (qrcode2.isDark(row, col)) {
          darkCount += 1;
        }
      }
    }
    const ratio = Math.abs(100 * darkCount / moduleCount / moduleCount - 50) / 5;
    lostPoint += ratio * 10;
    return lostPoint;
  };
  return _this;
})();
var QRMath = (function() {
  const EXP_TABLE = new Array(256);
  const LOG_TABLE = new Array(256);
  for (let i = 0; i < 8; i += 1) {
    EXP_TABLE[i] = 1 << i;
  }
  for (let i = 8; i < 256; i += 1) {
    EXP_TABLE[i] = EXP_TABLE[i - 4] ^ EXP_TABLE[i - 5] ^ EXP_TABLE[i - 6] ^ EXP_TABLE[i - 8];
  }
  for (let i = 0; i < 255; i += 1) {
    LOG_TABLE[EXP_TABLE[i]] = i;
  }
  const _this = {};
  _this.glog = function(n) {
    if (n < 1) {
      throw "glog(" + n + ")";
    }
    return LOG_TABLE[n];
  };
  _this.gexp = function(n) {
    while (n < 0) {
      n += 255;
    }
    while (n >= 256) {
      n -= 255;
    }
    return EXP_TABLE[n];
  };
  return _this;
})();
var qrPolynomial = /* @__PURE__ */ __name(function(num, shift) {
  if (typeof num.length == "undefined") {
    throw num.length + "/" + shift;
  }
  const _num = (function() {
    let offset = 0;
    while (offset < num.length && num[offset] == 0) {
      offset += 1;
    }
    const _num2 = new Array(num.length - offset + shift);
    for (let i = 0; i < num.length - offset; i += 1) {
      _num2[i] = num[i + offset];
    }
    return _num2;
  })();
  const _this = {};
  _this.getAt = function(index) {
    return _num[index];
  };
  _this.getLength = function() {
    return _num.length;
  };
  _this.multiply = function(e) {
    const num2 = new Array(_this.getLength() + e.getLength() - 1);
    for (let i = 0; i < _this.getLength(); i += 1) {
      for (let j = 0; j < e.getLength(); j += 1) {
        num2[i + j] ^= QRMath.gexp(QRMath.glog(_this.getAt(i)) + QRMath.glog(e.getAt(j)));
      }
    }
    return qrPolynomial(num2, 0);
  };
  _this.mod = function(e) {
    if (_this.getLength() - e.getLength() < 0) {
      return _this;
    }
    const ratio = QRMath.glog(_this.getAt(0)) - QRMath.glog(e.getAt(0));
    const num2 = new Array(_this.getLength());
    for (let i = 0; i < _this.getLength(); i += 1) {
      num2[i] = _this.getAt(i);
    }
    for (let i = 0; i < e.getLength(); i += 1) {
      num2[i] ^= QRMath.gexp(QRMath.glog(e.getAt(i)) + ratio);
    }
    return qrPolynomial(num2, 0).mod(e);
  };
  return _this;
}, "qrPolynomial");
var QRRSBlock = (function() {
  const RS_BLOCK_TABLE = [
    // L
    // M
    // Q
    // H
    // 1
    [1, 26, 19],
    [1, 26, 16],
    [1, 26, 13],
    [1, 26, 9],
    // 2
    [1, 44, 34],
    [1, 44, 28],
    [1, 44, 22],
    [1, 44, 16],
    // 3
    [1, 70, 55],
    [1, 70, 44],
    [2, 35, 17],
    [2, 35, 13],
    // 4
    [1, 100, 80],
    [2, 50, 32],
    [2, 50, 24],
    [4, 25, 9],
    // 5
    [1, 134, 108],
    [2, 67, 43],
    [2, 33, 15, 2, 34, 16],
    [2, 33, 11, 2, 34, 12],
    // 6
    [2, 86, 68],
    [4, 43, 27],
    [4, 43, 19],
    [4, 43, 15],
    // 7
    [2, 98, 78],
    [4, 49, 31],
    [2, 32, 14, 4, 33, 15],
    [4, 39, 13, 1, 40, 14],
    // 8
    [2, 121, 97],
    [2, 60, 38, 2, 61, 39],
    [4, 40, 18, 2, 41, 19],
    [4, 40, 14, 2, 41, 15],
    // 9
    [2, 146, 116],
    [3, 58, 36, 2, 59, 37],
    [4, 36, 16, 4, 37, 17],
    [4, 36, 12, 4, 37, 13],
    // 10
    [2, 86, 68, 2, 87, 69],
    [4, 69, 43, 1, 70, 44],
    [6, 43, 19, 2, 44, 20],
    [6, 43, 15, 2, 44, 16],
    // 11
    [4, 101, 81],
    [1, 80, 50, 4, 81, 51],
    [4, 50, 22, 4, 51, 23],
    [3, 36, 12, 8, 37, 13],
    // 12
    [2, 116, 92, 2, 117, 93],
    [6, 58, 36, 2, 59, 37],
    [4, 46, 20, 6, 47, 21],
    [7, 42, 14, 4, 43, 15],
    // 13
    [4, 133, 107],
    [8, 59, 37, 1, 60, 38],
    [8, 44, 20, 4, 45, 21],
    [12, 33, 11, 4, 34, 12],
    // 14
    [3, 145, 115, 1, 146, 116],
    [4, 64, 40, 5, 65, 41],
    [11, 36, 16, 5, 37, 17],
    [11, 36, 12, 5, 37, 13],
    // 15
    [5, 109, 87, 1, 110, 88],
    [5, 65, 41, 5, 66, 42],
    [5, 54, 24, 7, 55, 25],
    [11, 36, 12, 7, 37, 13],
    // 16
    [5, 122, 98, 1, 123, 99],
    [7, 73, 45, 3, 74, 46],
    [15, 43, 19, 2, 44, 20],
    [3, 45, 15, 13, 46, 16],
    // 17
    [1, 135, 107, 5, 136, 108],
    [10, 74, 46, 1, 75, 47],
    [1, 50, 22, 15, 51, 23],
    [2, 42, 14, 17, 43, 15],
    // 18
    [5, 150, 120, 1, 151, 121],
    [9, 69, 43, 4, 70, 44],
    [17, 50, 22, 1, 51, 23],
    [2, 42, 14, 19, 43, 15],
    // 19
    [3, 141, 113, 4, 142, 114],
    [3, 70, 44, 11, 71, 45],
    [17, 47, 21, 4, 48, 22],
    [9, 39, 13, 16, 40, 14],
    // 20
    [3, 135, 107, 5, 136, 108],
    [3, 67, 41, 13, 68, 42],
    [15, 54, 24, 5, 55, 25],
    [15, 43, 15, 10, 44, 16],
    // 21
    [4, 144, 116, 4, 145, 117],
    [17, 68, 42],
    [17, 50, 22, 6, 51, 23],
    [19, 46, 16, 6, 47, 17],
    // 22
    [2, 139, 111, 7, 140, 112],
    [17, 74, 46],
    [7, 54, 24, 16, 55, 25],
    [34, 37, 13],
    // 23
    [4, 151, 121, 5, 152, 122],
    [4, 75, 47, 14, 76, 48],
    [11, 54, 24, 14, 55, 25],
    [16, 45, 15, 14, 46, 16],
    // 24
    [6, 147, 117, 4, 148, 118],
    [6, 73, 45, 14, 74, 46],
    [11, 54, 24, 16, 55, 25],
    [30, 46, 16, 2, 47, 17],
    // 25
    [8, 132, 106, 4, 133, 107],
    [8, 75, 47, 13, 76, 48],
    [7, 54, 24, 22, 55, 25],
    [22, 45, 15, 13, 46, 16],
    // 26
    [10, 142, 114, 2, 143, 115],
    [19, 74, 46, 4, 75, 47],
    [28, 50, 22, 6, 51, 23],
    [33, 46, 16, 4, 47, 17],
    // 27
    [8, 152, 122, 4, 153, 123],
    [22, 73, 45, 3, 74, 46],
    [8, 53, 23, 26, 54, 24],
    [12, 45, 15, 28, 46, 16],
    // 28
    [3, 147, 117, 10, 148, 118],
    [3, 73, 45, 23, 74, 46],
    [4, 54, 24, 31, 55, 25],
    [11, 45, 15, 31, 46, 16],
    // 29
    [7, 146, 116, 7, 147, 117],
    [21, 73, 45, 7, 74, 46],
    [1, 53, 23, 37, 54, 24],
    [19, 45, 15, 26, 46, 16],
    // 30
    [5, 145, 115, 10, 146, 116],
    [19, 75, 47, 10, 76, 48],
    [15, 54, 24, 25, 55, 25],
    [23, 45, 15, 25, 46, 16],
    // 31
    [13, 145, 115, 3, 146, 116],
    [2, 74, 46, 29, 75, 47],
    [42, 54, 24, 1, 55, 25],
    [23, 45, 15, 28, 46, 16],
    // 32
    [17, 145, 115],
    [10, 74, 46, 23, 75, 47],
    [10, 54, 24, 35, 55, 25],
    [19, 45, 15, 35, 46, 16],
    // 33
    [17, 145, 115, 1, 146, 116],
    [14, 74, 46, 21, 75, 47],
    [29, 54, 24, 19, 55, 25],
    [11, 45, 15, 46, 46, 16],
    // 34
    [13, 145, 115, 6, 146, 116],
    [14, 74, 46, 23, 75, 47],
    [44, 54, 24, 7, 55, 25],
    [59, 46, 16, 1, 47, 17],
    // 35
    [12, 151, 121, 7, 152, 122],
    [12, 75, 47, 26, 76, 48],
    [39, 54, 24, 14, 55, 25],
    [22, 45, 15, 41, 46, 16],
    // 36
    [6, 151, 121, 14, 152, 122],
    [6, 75, 47, 34, 76, 48],
    [46, 54, 24, 10, 55, 25],
    [2, 45, 15, 64, 46, 16],
    // 37
    [17, 152, 122, 4, 153, 123],
    [29, 74, 46, 14, 75, 47],
    [49, 54, 24, 10, 55, 25],
    [24, 45, 15, 46, 46, 16],
    // 38
    [4, 152, 122, 18, 153, 123],
    [13, 74, 46, 32, 75, 47],
    [48, 54, 24, 14, 55, 25],
    [42, 45, 15, 32, 46, 16],
    // 39
    [20, 147, 117, 4, 148, 118],
    [40, 75, 47, 7, 76, 48],
    [43, 54, 24, 22, 55, 25],
    [10, 45, 15, 67, 46, 16],
    // 40
    [19, 148, 118, 6, 149, 119],
    [18, 75, 47, 31, 76, 48],
    [34, 54, 24, 34, 55, 25],
    [20, 45, 15, 61, 46, 16]
  ];
  const qrRSBlock = /* @__PURE__ */ __name(function(totalCount, dataCount) {
    const _this2 = {};
    _this2.totalCount = totalCount;
    _this2.dataCount = dataCount;
    return _this2;
  }, "qrRSBlock");
  const _this = {};
  const getRsBlockTable = /* @__PURE__ */ __name(function(typeNumber, errorCorrectionLevel) {
    switch (errorCorrectionLevel) {
      case QRErrorCorrectionLevel.L:
        return RS_BLOCK_TABLE[(typeNumber - 1) * 4 + 0];
      case QRErrorCorrectionLevel.M:
        return RS_BLOCK_TABLE[(typeNumber - 1) * 4 + 1];
      case QRErrorCorrectionLevel.Q:
        return RS_BLOCK_TABLE[(typeNumber - 1) * 4 + 2];
      case QRErrorCorrectionLevel.H:
        return RS_BLOCK_TABLE[(typeNumber - 1) * 4 + 3];
      default:
        return void 0;
    }
  }, "getRsBlockTable");
  _this.getRSBlocks = function(typeNumber, errorCorrectionLevel) {
    const rsBlock = getRsBlockTable(typeNumber, errorCorrectionLevel);
    if (typeof rsBlock == "undefined") {
      throw "bad rs block @ typeNumber:" + typeNumber + "/errorCorrectionLevel:" + errorCorrectionLevel;
    }
    const length = rsBlock.length / 3;
    const list = [];
    for (let i = 0; i < length; i += 1) {
      const count = rsBlock[i * 3 + 0];
      const totalCount = rsBlock[i * 3 + 1];
      const dataCount = rsBlock[i * 3 + 2];
      for (let j = 0; j < count; j += 1) {
        list.push(qrRSBlock(totalCount, dataCount));
      }
    }
    return list;
  };
  return _this;
})();
var qrBitBuffer = /* @__PURE__ */ __name(function() {
  const _buffer = [];
  let _length = 0;
  const _this = {};
  _this.getBuffer = function() {
    return _buffer;
  };
  _this.getAt = function(index) {
    const bufIndex = Math.floor(index / 8);
    return (_buffer[bufIndex] >>> 7 - index % 8 & 1) == 1;
  };
  _this.put = function(num, length) {
    for (let i = 0; i < length; i += 1) {
      _this.putBit((num >>> length - i - 1 & 1) == 1);
    }
  };
  _this.getLengthInBits = function() {
    return _length;
  };
  _this.putBit = function(bit) {
    const bufIndex = Math.floor(_length / 8);
    if (_buffer.length <= bufIndex) {
      _buffer.push(0);
    }
    if (bit) {
      _buffer[bufIndex] |= 128 >>> _length % 8;
    }
    _length += 1;
  };
  return _this;
}, "qrBitBuffer");
var qrNumber = /* @__PURE__ */ __name(function(data) {
  const _mode = QRMode.MODE_NUMBER;
  const _data = data;
  const _this = {};
  _this.getMode = function() {
    return _mode;
  };
  _this.getLength = function(buffer) {
    return _data.length;
  };
  _this.write = function(buffer) {
    const data2 = _data;
    let i = 0;
    while (i + 2 < data2.length) {
      buffer.put(strToNum(data2.substring(i, i + 3)), 10);
      i += 3;
    }
    if (i < data2.length) {
      if (data2.length - i == 1) {
        buffer.put(strToNum(data2.substring(i, i + 1)), 4);
      } else if (data2.length - i == 2) {
        buffer.put(strToNum(data2.substring(i, i + 2)), 7);
      }
    }
  };
  const strToNum = /* @__PURE__ */ __name(function(s) {
    let num = 0;
    for (let i = 0; i < s.length; i += 1) {
      num = num * 10 + chatToNum(s.charAt(i));
    }
    return num;
  }, "strToNum");
  const chatToNum = /* @__PURE__ */ __name(function(c) {
    if ("0" <= c && c <= "9") {
      return c.charCodeAt(0) - "0".charCodeAt(0);
    }
    throw "illegal char :" + c;
  }, "chatToNum");
  return _this;
}, "qrNumber");
var qrAlphaNum = /* @__PURE__ */ __name(function(data) {
  const _mode = QRMode.MODE_ALPHA_NUM;
  const _data = data;
  const _this = {};
  _this.getMode = function() {
    return _mode;
  };
  _this.getLength = function(buffer) {
    return _data.length;
  };
  _this.write = function(buffer) {
    const s = _data;
    let i = 0;
    while (i + 1 < s.length) {
      buffer.put(
        getCode(s.charAt(i)) * 45 + getCode(s.charAt(i + 1)),
        11
      );
      i += 2;
    }
    if (i < s.length) {
      buffer.put(getCode(s.charAt(i)), 6);
    }
  };
  const getCode = /* @__PURE__ */ __name(function(c) {
    if ("0" <= c && c <= "9") {
      return c.charCodeAt(0) - "0".charCodeAt(0);
    } else if ("A" <= c && c <= "Z") {
      return c.charCodeAt(0) - "A".charCodeAt(0) + 10;
    } else {
      switch (c) {
        case " ":
          return 36;
        case "$":
          return 37;
        case "%":
          return 38;
        case "*":
          return 39;
        case "+":
          return 40;
        case "-":
          return 41;
        case ".":
          return 42;
        case "/":
          return 43;
        case ":":
          return 44;
        default:
          throw "illegal char :" + c;
      }
    }
  }, "getCode");
  return _this;
}, "qrAlphaNum");
var qr8BitByte = /* @__PURE__ */ __name(function(data) {
  const _mode = QRMode.MODE_8BIT_BYTE;
  const _data = data;
  const _bytes = qrcode.stringToBytes(data);
  const _this = {};
  _this.getMode = function() {
    return _mode;
  };
  _this.getLength = function(buffer) {
    return _bytes.length;
  };
  _this.write = function(buffer) {
    for (let i = 0; i < _bytes.length; i += 1) {
      buffer.put(_bytes[i], 8);
    }
  };
  return _this;
}, "qr8BitByte");
var qrKanji = /* @__PURE__ */ __name(function(data) {
  const _mode = QRMode.MODE_KANJI;
  const _data = data;
  const stringToBytes2 = qrcode.stringToBytes;
  !(function(c, code) {
    const test = stringToBytes2(c);
    if (test.length != 2 || (test[0] << 8 | test[1]) != code) {
      throw "sjis not supported.";
    }
  })("\u53CB", 38726);
  const _bytes = stringToBytes2(data);
  const _this = {};
  _this.getMode = function() {
    return _mode;
  };
  _this.getLength = function(buffer) {
    return ~~(_bytes.length / 2);
  };
  _this.write = function(buffer) {
    const data2 = _bytes;
    let i = 0;
    while (i + 1 < data2.length) {
      let c = (255 & data2[i]) << 8 | 255 & data2[i + 1];
      if (33088 <= c && c <= 40956) {
        c -= 33088;
      } else if (57408 <= c && c <= 60351) {
        c -= 49472;
      } else {
        throw "illegal char at " + (i + 1) + "/" + c;
      }
      c = (c >>> 8 & 255) * 192 + (c & 255);
      buffer.put(c, 13);
      i += 2;
    }
    if (i < data2.length) {
      throw "illegal char at " + (i + 1);
    }
  };
  return _this;
}, "qrKanji");
var byteArrayOutputStream = /* @__PURE__ */ __name(function() {
  const _bytes = [];
  const _this = {};
  _this.writeByte = function(b) {
    _bytes.push(b & 255);
  };
  _this.writeShort = function(i) {
    _this.writeByte(i);
    _this.writeByte(i >>> 8);
  };
  _this.writeBytes = function(b, off, len) {
    off = off || 0;
    len = len || b.length;
    for (let i = 0; i < len; i += 1) {
      _this.writeByte(b[i + off]);
    }
  };
  _this.writeString = function(s) {
    for (let i = 0; i < s.length; i += 1) {
      _this.writeByte(s.charCodeAt(i));
    }
  };
  _this.toByteArray = function() {
    return _bytes;
  };
  _this.toString = function() {
    let s = "";
    s += "[";
    for (let i = 0; i < _bytes.length; i += 1) {
      if (i > 0) {
        s += ",";
      }
      s += _bytes[i];
    }
    s += "]";
    return s;
  };
  return _this;
}, "byteArrayOutputStream");
var base64EncodeOutputStream = /* @__PURE__ */ __name(function() {
  let _buffer = 0;
  let _buflen = 0;
  let _length = 0;
  let _base64 = "";
  const _this = {};
  const writeEncoded = /* @__PURE__ */ __name(function(b) {
    _base64 += String.fromCharCode(encode(b & 63));
  }, "writeEncoded");
  const encode = /* @__PURE__ */ __name(function(n) {
    if (n < 0) {
      throw "n:" + n;
    } else if (n < 26) {
      return 65 + n;
    } else if (n < 52) {
      return 97 + (n - 26);
    } else if (n < 62) {
      return 48 + (n - 52);
    } else if (n == 62) {
      return 43;
    } else if (n == 63) {
      return 47;
    } else {
      throw "n:" + n;
    }
  }, "encode");
  _this.writeByte = function(n) {
    _buffer = _buffer << 8 | n & 255;
    _buflen += 8;
    _length += 1;
    while (_buflen >= 6) {
      writeEncoded(_buffer >>> _buflen - 6);
      _buflen -= 6;
    }
  };
  _this.flush = function() {
    if (_buflen > 0) {
      writeEncoded(_buffer << 6 - _buflen);
      _buffer = 0;
      _buflen = 0;
    }
    if (_length % 3 != 0) {
      const padlen = 3 - _length % 3;
      for (let i = 0; i < padlen; i += 1) {
        _base64 += "=";
      }
    }
  };
  _this.toString = function() {
    return _base64;
  };
  return _this;
}, "base64EncodeOutputStream");
var base64DecodeInputStream = /* @__PURE__ */ __name(function(str) {
  const _str = str;
  let _pos = 0;
  let _buffer = 0;
  let _buflen = 0;
  const _this = {};
  _this.read = function() {
    while (_buflen < 8) {
      if (_pos >= _str.length) {
        if (_buflen == 0) {
          return -1;
        }
        throw "unexpected end of file./" + _buflen;
      }
      const c = _str.charAt(_pos);
      _pos += 1;
      if (c == "=") {
        _buflen = 0;
        return -1;
      } else if (c.match(/^\s$/)) {
        continue;
      }
      _buffer = _buffer << 6 | decode(c.charCodeAt(0));
      _buflen += 6;
    }
    const n = _buffer >>> _buflen - 8 & 255;
    _buflen -= 8;
    return n;
  };
  const decode = /* @__PURE__ */ __name(function(c) {
    if (65 <= c && c <= 90) {
      return c - 65;
    } else if (97 <= c && c <= 122) {
      return c - 97 + 26;
    } else if (48 <= c && c <= 57) {
      return c - 48 + 52;
    } else if (c == 43) {
      return 62;
    } else if (c == 47) {
      return 63;
    } else {
      throw "c:" + c;
    }
  }, "decode");
  return _this;
}, "base64DecodeInputStream");
var gifImage = /* @__PURE__ */ __name(function(width, height) {
  const _width = width;
  const _height = height;
  const _data = new Array(width * height);
  const _this = {};
  _this.setPixel = function(x, y, pixel) {
    _data[y * _width + x] = pixel;
  };
  _this.write = function(out) {
    out.writeString("GIF87a");
    out.writeShort(_width);
    out.writeShort(_height);
    out.writeByte(128);
    out.writeByte(0);
    out.writeByte(0);
    out.writeByte(0);
    out.writeByte(0);
    out.writeByte(0);
    out.writeByte(255);
    out.writeByte(255);
    out.writeByte(255);
    out.writeString(",");
    out.writeShort(0);
    out.writeShort(0);
    out.writeShort(_width);
    out.writeShort(_height);
    out.writeByte(0);
    const lzwMinCodeSize = 2;
    const raster = getLZWRaster(lzwMinCodeSize);
    out.writeByte(lzwMinCodeSize);
    let offset = 0;
    while (raster.length - offset > 255) {
      out.writeByte(255);
      out.writeBytes(raster, offset, 255);
      offset += 255;
    }
    out.writeByte(raster.length - offset);
    out.writeBytes(raster, offset, raster.length - offset);
    out.writeByte(0);
    out.writeString(";");
  };
  const bitOutputStream = /* @__PURE__ */ __name(function(out) {
    const _out = out;
    let _bitLength = 0;
    let _bitBuffer = 0;
    const _this2 = {};
    _this2.write = function(data, length) {
      if (data >>> length != 0) {
        throw "length over";
      }
      while (_bitLength + length >= 8) {
        _out.writeByte(255 & (data << _bitLength | _bitBuffer));
        length -= 8 - _bitLength;
        data >>>= 8 - _bitLength;
        _bitBuffer = 0;
        _bitLength = 0;
      }
      _bitBuffer = data << _bitLength | _bitBuffer;
      _bitLength = _bitLength + length;
    };
    _this2.flush = function() {
      if (_bitLength > 0) {
        _out.writeByte(_bitBuffer);
      }
    };
    return _this2;
  }, "bitOutputStream");
  const getLZWRaster = /* @__PURE__ */ __name(function(lzwMinCodeSize) {
    const clearCode = 1 << lzwMinCodeSize;
    const endCode = (1 << lzwMinCodeSize) + 1;
    let bitLength = lzwMinCodeSize + 1;
    const table = lzwTable();
    for (let i = 0; i < clearCode; i += 1) {
      table.add(String.fromCharCode(i));
    }
    table.add(String.fromCharCode(clearCode));
    table.add(String.fromCharCode(endCode));
    const byteOut = byteArrayOutputStream();
    const bitOut = bitOutputStream(byteOut);
    bitOut.write(clearCode, bitLength);
    let dataIndex = 0;
    let s = String.fromCharCode(_data[dataIndex]);
    dataIndex += 1;
    while (dataIndex < _data.length) {
      const c = String.fromCharCode(_data[dataIndex]);
      dataIndex += 1;
      if (table.contains(s + c)) {
        s = s + c;
      } else {
        bitOut.write(table.indexOf(s), bitLength);
        if (table.size() < 4095) {
          if (table.size() == 1 << bitLength) {
            bitLength += 1;
          }
          table.add(s + c);
        }
        s = c;
      }
    }
    bitOut.write(table.indexOf(s), bitLength);
    bitOut.write(endCode, bitLength);
    bitOut.flush();
    return byteOut.toByteArray();
  }, "getLZWRaster");
  const lzwTable = /* @__PURE__ */ __name(function() {
    const _map = {};
    let _size = 0;
    const _this2 = {};
    _this2.add = function(key) {
      if (_this2.contains(key)) {
        throw "dup key:" + key;
      }
      _map[key] = _size;
      _size += 1;
    };
    _this2.size = function() {
      return _size;
    };
    _this2.indexOf = function(key) {
      return _map[key];
    };
    _this2.contains = function(key) {
      return typeof _map[key] != "undefined";
    };
    return _this2;
  }, "lzwTable");
  return _this;
}, "gifImage");
var createDataURL = /* @__PURE__ */ __name(function(width, height, getPixel) {
  const gif = gifImage(width, height);
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      gif.setPixel(x, y, getPixel(x, y));
    }
  }
  const b = byteArrayOutputStream();
  gif.write(b);
  const base64 = base64EncodeOutputStream();
  const bytes = b.toByteArray();
  for (let i = 0; i < bytes.length; i += 1) {
    base64.writeByte(bytes[i]);
  }
  base64.flush();
  return "data:image/gif;base64," + base64;
}, "createDataURL");
var qrcode_default = qrcode;
var stringToBytes = qrcode.stringToBytes;

// worker.js
var EBAY_CACHE_TTL_DAYS = 7;
var BARCODE_CACHE_TTL_DAYS = 90;
var DAILY_SEED_LIMIT = 40;
var EBAY_HOST = "ebay-average-selling-price.p.rapidapi.com";
var BRICKSET_KEY_FALLBACK = "3-Dwg8-SY9s-4VdM8";
var RB_DISCOVERY_PAGE_SIZE = 50;
var MIN_YEAR = 2015;
var BRICKSET_DELAY_MS = 2e3;
var MONTHLY_CATCHUP_PAGES = 4;
var MONTHLY_CATCHUP_DAY_CUTOFF = 3;
var DEAL_CRON = "0 */6 * * *";
var ALLOWED = ["rebrickable.com/api", "api.brickowl.com"];
var COMMUNITY_SUBMIT_COOLDOWN_MS = 6 * 60 * 60 * 1e3;
var TRUSTED_SUBMIT_COOLDOWN_MS = 2 * 60 * 60 * 1e3;
var BRIKS_PER_LIKE = 1;
var COMMUNITY_POST_LIFETIME_MS = 6 * 24 * 60 * 60 * 1e3;
var AMAZON_TAG = "brikstax-20";
var EBAY_CAMPAIGN_ID = "5339171029";
var CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, x-rapidapi-key, x-rapidapi-host, x-brikstax-secret"
};
var json = /* @__PURE__ */ __name((data, status = 200) => new Response(JSON.stringify(data), {
  status,
  headers: { "Content-Type": "application/json", ...CORS }
}), "json");
var err = /* @__PURE__ */ __name((msg, status = 400) => json({ error: msg }, status), "err");
var _rbKeyIdx = 0;
function nextRbKey(env) {
  const keys = [env.RB_KEY, env.RB_KEY2, env.RB_KEY3].filter(Boolean);
  if (keys.length === 0) return null;
  const key = keys[_rbKeyIdx % keys.length];
  _rbKeyIdx++;
  return key;
}
__name(nextRbKey, "nextRbKey");
async function rbFetch(pathOrUrl, env) {
  const key = nextRbKey(env);
  if (!key) throw new Error("No Rebrickable key configured");
  const url = pathOrUrl.startsWith("http") ? pathOrUrl : `https://rebrickable.com/api/v3/lego/${pathOrUrl}`;
  return fetch(url, { headers: { Authorization: `key ${key}`, Accept: "application/json" } });
}
__name(rbFetch, "rbFetch");
async function handleFeatureFlags(env) {
  return json({
    community_feed: env.FEATURE_COMMUNITY_FEED === "true",
    scanner: env.FEATURE_SCANNER === "true",
    community_banner: env.COMMUNITY_BANNER || null
  });
}
__name(handleFeatureFlags, "handleFeatureFlags");
var worker_default = {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") return new Response(null, { headers: CORS });
    const url = new URL(request.url);
    const path = url.pathname;
    if (path === "/health")
      return json({ ok: true, db: !!env.PRICE_CACHE, ts: Date.now() });
    if (path === "/features" && request.method === "GET")
      return handleFeatureFlags(env);
    if (path === "/parts" && request.method === "GET") return handleParts(url, env);
    if (path === "/parts-merge" && request.method === "POST") return handlePartsMerge(request, env);
    if (path === "/community/submit" && request.method === "POST") return handleCommunitySubmit(request, env, ctx);
    if (path === "/community/feed" && request.method === "GET") return handleCommunityFeed(url, env);
    if (path === "/community/like" && request.method === "POST") return handleCommunityLike(request, env);
    if (path === "/community/claim-rewards" && request.method === "POST") return handleCommunityClaimRewards(request, env);
    if (path === "/community/moderate" && request.method === "POST") return handleCommunityModerate(request, env);
    if (path === "/push/register" && request.method === "POST") return handlePushRegister(request, env);
    if (path === "/push/send" && request.method === "POST") return handlePushSend(request, env);
    if (path.startsWith("/community/photo/") && request.method === "GET") return handleCommunityPhoto(url, env);
    if (path === "/ebay" && request.method === "POST") return handleEbay(request, env);
    if (path === "/ebay" && request.method === "GET") return checkEbayCache(url, env);
    if (path === "/ebay/usage" && request.method === "GET") return handleEbayUsage(env);
    if (path === "/barcode/cache" && request.method === "POST") return handleBarcodeCache(request, env);
    if (path === "/barcode" && request.method === "GET") return handleBarcode(url, env);
    if (path === "/barcode/submit" && request.method === "POST") return handleBarcodeSubmit(request, env);
    if (path === "/news" && request.method === "GET") return handleNewsGet(url, env);
    if (path === "/news" && request.method === "POST") return handleNewsPost(request, env);
    if (path === "/news/clear" && request.method === "POST") return handleNewsClear(request, env);
    if (path === "/deals" && request.method === "GET") return handleDealsGet(url, env);
    if (path === "/deals/add" && request.method === "POST") return handleDealsAdd(request, env);
    if (path === "/deals/clear" && request.method === "POST") return handleDealsClear(request, env);
    if (path === "/deals/check" && request.method === "GET") return json(await checkSlickdealsForDealCandidates(env));
    if (path === "/qr" && request.method === "GET") return handleQrCode(url);
    if (path === "/seed/status" && request.method === "GET") return handleSeedStatus(env);
    if (path === "/seed/run" && request.method === "GET") return handleSeedRun(env);
    if (path === "/seed/errors" && request.method === "GET") return handleSeedErrors(env);
    if (path === "/debug" && request.method === "GET") return handleDebug(url, env);
    if (path === "/discord" && request.method === "POST") return handleDiscord(request, env, ctx);
    if (path === "/" || path === "") return handleProxy(url);
    return err("Not found", 404);
  },
  async scheduled(event, env, ctx) {
    console.log("Cron trigger fired:", (/* @__PURE__ */ new Date()).toISOString(), "cron:", event.cron);
    if (event.cron === DEAL_CRON) {
      ctx.waitUntil(checkSlickdealsForDealCandidates(env));
      return;
    }
    ctx.waitUntil(runSeedBatch(env));
    ctx.waitUntil(cleanupExpiredCommunityPosts(env));
    ctx.waitUntil(checkRssForNewsCandidates(env));
  }
};
async function handleQrCode(url) {
  const text = url.searchParams.get("text");
  if (!text) return err("Missing text param");
  if (text.length > 2e3) return err("text too long (max 2000 chars)", 413);
  const ecParam = (url.searchParams.get("ec") || "Q").toUpperCase();
  const errorCorrectionLevel = ["L", "M", "Q", "H"].includes(ecParam) ? ecParam : "Q";
  const cellParam = parseInt(url.searchParams.get("cell") || "8", 10);
  const cellSize = Number.isFinite(cellParam) ? Math.min(Math.max(cellParam, 1), 40) : 8;
  try {
    const qr = qrcode_default(0, errorCorrectionLevel);
    qr.addData(text);
    qr.make();
    const svg = qr.createSvgTag({ cellSize, margin: cellSize });
    return new Response(svg, {
      headers: {
        "content-type": "image/svg+xml",
        "cache-control": "public, max-age=604800",
        // a week -- same text always encodes to the same QR
        ...CORS
      }
    });
  } catch (e) {
    return err(`QR generation failed: ${e.message}`, 500);
  }
}
__name(handleQrCode, "handleQrCode");
async function handleParts(url, env) {
  if (!env.RB_KEY) return err("Server configuration error", 500);
  let setNum = (url.searchParams.get("set") || "").trim();
  if (!setNum) return err("Missing set param");
  if (!setNum.includes("-")) setNum = setNum + "-1";
  async function rb(path) {
    const res = await rbFetch(path, env);
    if (!res.ok) throw new Error(`Rebrickable ${res.status} for ${path}`);
    return res.json();
  }
  __name(rb, "rb");
  try {
    const setData = await rb(`sets/${setNum}/`);
    let allParts = [];
    let nextPath = `sets/${setNum}/parts/?page_size=100`;
    while (nextPath) {
      const d = await rb(nextPath);
      allParts = allParts.concat(d.results || []);
      if (d.next) {
        const u = new URL(d.next);
        nextPath = `sets/${setNum}/parts/${u.search}`;
      } else {
        nextPath = null;
      }
    }
    const partsMap = /* @__PURE__ */ new Map();
    for (const p of allParts) {
      const key = `${p.part.part_num}__${p.color.id}`;
      if (partsMap.has(key)) {
        partsMap.get(key).qty += p.quantity;
      } else {
        partsMap.set(key, {
          id: key,
          partNum: p.part.part_num,
          name: p.part.name,
          color: p.color.name,
          colorHex: p.color.rgb ? "#" + p.color.rgb : null,
          qty: p.quantity,
          imgUrl: p.part.part_img_url || null
        });
      }
    }
    const parts = [...partsMap.values()];
    return json({
      set: {
        num: setData.set_num,
        name: setData.name,
        year: setData.year,
        numParts: setData.num_parts,
        imgUrl: setData.set_img_url || null
      },
      parts
    });
  } catch (e) {
    return err(e.message, 502);
  }
}
__name(handleParts, "handleParts");
async function handlePartsMerge(req, env) {
  let body;
  try {
    body = await req.json();
  } catch {
    return err("Invalid JSON body");
  }
  const ids = Array.isArray(body.ids) ? [...new Set(body.ids.map((s) => String(s).trim()).filter(Boolean))] : [];
  if (ids.length === 0) return err("No valid Set/MOC IDs provided");
  if (ids.length > 20) return err("Too many sets at once (max 20)");
  if (!env.RB_KEY) return err("Server configuration error", 500);
  async function rb(path) {
    const res = await rbFetch(path, env);
    if (!res.ok) throw new Error(`Rebrickable ${res.status}`);
    return res.json();
  }
  __name(rb, "rb");
  const partsMap = /* @__PURE__ */ new Map();
  const failed = [];
  let setsResolved = 0;
  for (const rawId of ids) {
    if (rawId.toLowerCase().startsWith("moc")) {
      failed.push(`"${rawId}" -- MOCs aren't supported (Rebrickable removed MOC data from their API in 2020); only official LEGO set numbers work`);
      continue;
    }
    const idPath = `sets/${rawId.includes("-") ? rawId : rawId + "-1"}`;
    try {
      let allParts = [];
      let nextPath = `${idPath}/parts/?page_size=100`;
      while (nextPath) {
        const d = await rb(nextPath);
        allParts = allParts.concat(d.results || []);
        if (d.next) {
          const u = new URL(d.next);
          nextPath = `${idPath}/parts/${u.search}`;
        } else {
          nextPath = null;
        }
      }
      if (allParts.length === 0) {
        failed.push(`Could not find parts for "${rawId}" -- check the set number`);
        continue;
      }
      setsResolved++;
      for (const p of allParts) {
        const key = `${p.part.part_num}__${p.color.id}`;
        if (!partsMap.has(key)) {
          // Rebrickable's part/color objects already carry each catalog's
          // own numbering under external_ids -- BrickLink's part number and
          // color ID are NOT the same as Rebrickable's, so this is the only
          // correct source for a BrickLink-importable output. Not every
          // part/color has a known BrickLink mapping; blPartNum/blColorId
          // stay "" when absent and the client skips those rows out of the
          // XML rather than emitting a wrong or blank id.
          const blPartNum = p.part.external_ids?.BrickLink?.[0] || "";
          const blColorIdRaw = p.color.external_ids?.BrickLink?.ext_ids?.[0];
          const blColorId = blColorIdRaw === void 0 || blColorIdRaw === null ? "" : String(blColorIdRaw);
          partsMap.set(key, {
            partNum: p.part.part_num,
            name: p.part.name,
            colorId: p.color.id,
            color: p.color.name,
            qty: 0,
            spareQty: 0,
            blPartNum,
            blColorId
          });
        }
        const entry = partsMap.get(key);
        if (p.is_spare) entry.spareQty += p.quantity;
        else entry.qty += p.quantity;
      }
    } catch (e) {
      failed.push(`Error fetching "${rawId}": ${e.message}`);
    }
  }
  if (partsMap.size === 0) {
    return json({ success: false, error: "No parts found for any of the given IDs", warnings: failed }, 404);
  }
  const parts = [...partsMap.values()].sort((a, b) => a.partNum.localeCompare(b.partNum));
  let csv = "Part Number,BrickLink Part Number,Color ID,BrickLink Color ID,Color,Quantity,Spare Qty\n";
  for (const p of parts) {
    const colorField = p.color.includes(",") ? `"${p.color}"` : p.color;
    csv += `${p.partNum},${p.blPartNum},${p.colorId},${p.blColorId},${colorField},${p.qty},${p.spareQty}
`;
  }
  return json({
    success: true,
    csv,
    partCount: parts.length,
    setCount: setsResolved,
    // Real warnings now -- which input IDs actually failed to resolve and
    // why, instead of a fabricated per-part "replaced" claim. A typo'd set
    // number used to just silently vanish from the merged list with zero
    // feedback. Each entry in `failed` is already a complete, specific
    // message (MOC/not-found/fetch-error each read differently) -- no
    // further wrapping needed here.
    warnings: failed
  });
}
__name(handlePartsMerge, "handlePartsMerge");
async function handleNewsGet(url, env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  const limit = Math.min(parseInt(url.searchParams.get("limit") || "20"), 50);
  const type = url.searchParams.get("type");
  try {
    let rows;
    if (type) {
      rows = await env.PRICE_CACHE.prepare(
        "SELECT * FROM news WHERE type = ? ORDER BY posted_at DESC LIMIT ?"
      ).bind(type, limit).all();
    } else {
      rows = await env.PRICE_CACHE.prepare(
        "SELECT * FROM news ORDER BY posted_at DESC LIMIT ?"
      ).bind(limit).all();
    }
    return json({ items: rows.results || [] });
  } catch (e) {
    return err(`DB error: ${e.message}`, 500);
  }
}
__name(handleNewsGet, "handleNewsGet");
async function handleNewsPost(request, env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  const secret = request.headers.get("x-brikstax-secret");
  if (secret !== (env.NEWS_SECRET || "brikstax2026")) return err("Unauthorized", 401);
  let body;
  try {
    body = await request.json();
  } catch {
    return err("Invalid JSON");
  }
  const { title, summary, url, image_url } = body;
  if (!title) return err("Missing title");
  try {
    const result = await env.PRICE_CACHE.prepare(`
      INSERT INTO news (title, summary, url, image_url, posted_at, source, type)
      VALUES (?, ?, ?, ?, ?, 'discord', 'news')
    `).bind(title, summary || null, url || null, image_url || null, Date.now()).run();
    return json({ ok: true, id: result.meta?.last_row_id });
  } catch (e) {
    return err(`DB error: ${e.message}`, 500);
  }
}
__name(handleNewsPost, "handleNewsPost");
async function handleNewsClear(request, env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  const secret = request.headers.get("x-brikstax-secret");
  if (secret !== (env.NEWS_SECRET || "brikstax2026")) return err("Unauthorized", 401);
  let body;
  try {
    body = await request.json();
  } catch {
    body = {};
  }
  const days = body.days || 30;
  const cutoff = Date.now() - days * 24 * 60 * 60 * 1e3;
  try {
    const result = await env.PRICE_CACHE.prepare(
      "DELETE FROM news WHERE posted_at < ?"
    ).bind(cutoff).run();
    return json({ ok: true, deleted: result.meta?.changes ?? 0 });
  } catch (e) {
    return err(`DB error: ${e.message}`, 500);
  }
}
__name(handleNewsClear, "handleNewsClear");
function hexToBytes(hex) {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) bytes[i] = parseInt(hex.substr(i * 2, 2), 16);
  return bytes;
}
__name(hexToBytes, "hexToBytes");
async function verifyDiscordSignature(request, rawBody, publicKey) {
  const signature = request.headers.get("x-signature-ed25519");
  const timestamp = request.headers.get("x-signature-timestamp");
  if (!signature || !timestamp) return false;
  try {
    const key = await crypto.subtle.importKey(
      "raw",
      hexToBytes(publicKey),
      { name: "Ed25519", namedCurve: "Ed25519" },
      false,
      ["verify"]
    );
    const enc = new TextEncoder();
    const message = enc.encode(timestamp + rawBody);
    return await crypto.subtle.verify("Ed25519", key, hexToBytes(signature), message);
  } catch (e) {
    console.error("Discord sig verify error:", e.message);
    return false;
  }
}
__name(verifyDiscordSignature, "verifyDiscordSignature");
var DISCORD_PONG = 1;
var DISCORD_CHANNEL_MSG = 4;
var DISCORD_DEFERRED = 5;
var DISCORD_MODAL = 9;
function discordReply(content, ephemeral = true) {
  return new Response(JSON.stringify({
    type: DISCORD_CHANNEL_MSG,
    data: { content, flags: ephemeral ? 64 : 0 }
  }), { headers: { "Content-Type": "application/json" } });
}
__name(discordReply, "discordReply");
function opt(options, name) {
  if (!options) return null;
  const o = options.find((x) => x.name === name);
  return o ? o.value : null;
}
__name(opt, "opt");
async function handleDiscord(request, env, ctx) {
  const pubKey = env.DISCORD_PUBLIC_KEY;
  if (!pubKey) return new Response("DISCORD_PUBLIC_KEY not set", { status: 500 });
  const rawBody = await request.text();
  const valid = await verifyDiscordSignature(request, rawBody, pubKey);
  if (!valid) return new Response("Bad signature", { status: 401 });
  const body = JSON.parse(rawBody);
  if (body.type === 1) {
    return new Response(JSON.stringify({ type: DISCORD_PONG }), {
      headers: { "Content-Type": "application/json" }
    });
  }
  if (body.type === 3) {
    const customId = body.data.custom_id;
    if (customId && customId.startsWith("rss_post:")) {
      return handleRssPostButton(customId, env);
    }
    if (customId && customId.startsWith("mod_approve:")) {
      const id = customId.replace("mod_approve:", "");
      return handleDiscordModerate([{ name: "id", value: id }], env, "approve");
    }
    if (customId && customId.startsWith("mod_reject:")) {
      const id = customId.replace("mod_reject:", "");
      return handleDiscordModerate([{ name: "id", value: id }], env, "reject");
    }
    if (customId && customId.startsWith("deal_post:")) {
      return handleDealPostButton(customId, env);
    }
    return discordReply("\u2753 Unknown button.");
  }
  if (body.type === 5) {
    const customId = body.data.custom_id;
    if (customId && customId.startsWith("deal_modal:")) {
      return handleDealModalSubmit(customId, body, env);
    }
    return discordReply("\u2753 Unknown modal.");
  }
  if (body.type === 2) {
    const cmd = body.data.name;
    const options = body.data.options;
    if (cmd === "approve") return handleDiscordModerate(options, env, "approve");
    if (cmd === "reject") return handleDiscordModerate(options, env, "reject");
    if (cmd === "trust") return handleDiscordTrust(options, env, true);
    if (cmd === "untrust") return handleDiscordTrust(options, env, false);
    if (cmd === "news") {
      const title = opt(options, "title");
      const summary = opt(options, "summary");
      const url = opt(options, "url");
      const image = opt(options, "image");
      if (!title) return discordReply("\u274C Title is required.");
      try {
        const result = await env.PRICE_CACHE.prepare(`
          INSERT INTO news (title, summary, url, image_url, posted_at, source, type)
          VALUES (?, ?, ?, ?, ?, 'discord', 'news')
        `).bind(title, summary || null, url || null, image || null, Date.now()).run();
        const id = result.meta?.last_row_id;
        return discordReply(`\u2705 News posted (#${id}): **${title}**`);
      } catch (e) {
        return discordReply(`\u274C DB error: ${e.message}`);
      }
    }
    if (cmd === "newslink") {
      const linkUrl = opt(options, "url");
      if (!linkUrl) return discordReply("\u274C Missing url.");
      ctx.waitUntil(handleNewsLinkDeferred(linkUrl, body, env));
      return new Response(JSON.stringify({ type: DISCORD_DEFERRED }), {
        headers: { "Content-Type": "application/json" }
      });
    }
    if (cmd === "deallink") {
      const linkUrl = opt(options, "url");
      const price = opt(options, "price");
      if (!linkUrl) return discordReply("\u274C Missing url.");
      if (price == null) return discordReply("\u274C Missing price \u2014 retail price/title can be auto-filled, but the deal price itself has to be entered manually.");
      ctx.waitUntil(handleDealLinkDeferred(linkUrl, options, body, env));
      return new Response(JSON.stringify({ type: DISCORD_DEFERRED }), {
        headers: { "Content-Type": "application/json" }
      });
    }
    if (cmd === "update") {
      const title = opt(options, "title");
      const summary = opt(options, "summary");
      const version = opt(options, "version");
      if (!title) return discordReply("\u274C Title is required.");
      const fullTitle = version ? `${version} \u2014 ${title}` : title;
      try {
        const result = await env.PRICE_CACHE.prepare(`
          INSERT INTO news (title, summary, url, image_url, posted_at, source, type)
          VALUES (?, ?, ?, ?, ?, 'discord', 'update')
        `).bind(fullTitle, summary || null, null, null, Date.now()).run();
        const id = result.meta?.last_row_id;
        return discordReply(`\u2705 Update posted (#${id}, app + website): **${fullTitle}**`);
      } catch (e) {
        return discordReply(`\u274C DB error: ${e.message}`);
      }
    }
    if (cmd === "deal") {
      const title = opt(options, "title");
      const url = opt(options, "url");
      const setNum = opt(options, "set");
      const retail = opt(options, "retail");
      const price = opt(options, "price");
      const retailer = opt(options, "retailer");
      const image = opt(options, "image");
      const note = opt(options, "note");
      const featured = opt(options, "featured");
      const days = opt(options, "days");
      if (!title || !url) return discordReply("\u274C Title and url are required.");
      const expiresDays = days != null ? days : 30;
      const expires_at = Date.now() + expiresDays * 24 * 60 * 60 * 1e3;
      try {
        const result = await env.PRICE_CACHE.prepare(`
          INSERT INTO deals
            (deal_id, title, set_num, retail_price, deal_price,
             retailer, url, image_url, note, featured, expires_at, created_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
          null,
          title,
          setNum || null,
          retail != null ? retail : null,
          price != null ? price : null,
          retailer || null,
          url,
          image || null,
          note || null,
          featured ? 1 : 0,
          expires_at,
          Date.now()
        ).run();
        const id = result.meta?.last_row_id;
        const pct = retail && price ? ` (${Math.round((1 - price / retail) * 100)}% off)` : "";
        return discordReply(`\u2705 Deal posted (#${id}): **${title}**${pct}${featured ? " \u2B50 featured" : ""}`);
      } catch (e) {
        return discordReply(`\u274C DB error: ${e.message}`);
      }
    }
    if (cmd === "amazondeal") {
      const title = opt(options, "title");
      const url = opt(options, "url");
      const setNum = opt(options, "set");
      const retail = opt(options, "retail");
      const price = opt(options, "price");
      const image = opt(options, "image");
      const note = opt(options, "note");
      const featured = opt(options, "featured");
      const days = opt(options, "days");
      if (!title || !url) return discordReply("\u274C Title and url are required.");
      let affiliateUrl;
      try {
        affiliateUrl = buildAmazonAffiliateLink(url);
      } catch (e) {
        return discordReply("\u274C That doesn't look like a valid url.");
      }
      const expiresDays = days != null ? days : 30;
      const expires_at = Date.now() + expiresDays * 24 * 60 * 60 * 1e3;
      try {
        const result = await env.PRICE_CACHE.prepare(`
          INSERT INTO deals
            (deal_id, title, set_num, retail_price, deal_price,
             retailer, url, image_url, note, featured, expires_at, created_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
          null,
          title,
          setNum || null,
          retail != null ? retail : null,
          price != null ? price : null,
          "Amazon",
          affiliateUrl,
          image || null,
          note || null,
          featured ? 1 : 0,
          expires_at,
          Date.now()
        ).run();
        const id = result.meta?.last_row_id;
        const pct = retail && price ? ` (${Math.round((1 - price / retail) * 100)}% off)` : "";
        return discordReply(`\u2705 Amazon deal posted (#${id}): **${title}**${pct}${featured ? " \u2B50 featured" : ""}`);
      } catch (e) {
        return discordReply(`\u274C DB error: ${e.message}`);
      }
    }
    if (cmd === "ebaydeal") {
      const title = opt(options, "title");
      const url = opt(options, "url");
      const setNum = opt(options, "set");
      const retail = opt(options, "retail");
      const price = opt(options, "price");
      const image = opt(options, "image");
      const note = opt(options, "note");
      const featured = opt(options, "featured");
      const days = opt(options, "days");
      if (!title || !url) return discordReply("\u274C Title and url are required.");
      let affiliateUrl;
      try {
        affiliateUrl = buildEbayAffiliateLink(url);
      } catch (e) {
        return discordReply("\u274C That doesn't look like a valid url.");
      }
      const expiresDays = days != null ? days : 30;
      const expires_at = Date.now() + expiresDays * 24 * 60 * 60 * 1e3;
      try {
        const result = await env.PRICE_CACHE.prepare(`
          INSERT INTO deals
            (deal_id, title, set_num, retail_price, deal_price,
             retailer, url, image_url, note, featured, expires_at, created_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
          null,
          title,
          setNum || null,
          retail != null ? retail : null,
          price != null ? price : null,
          "eBay",
          affiliateUrl,
          image || null,
          note || null,
          featured ? 1 : 0,
          expires_at,
          Date.now()
        ).run();
        const id = result.meta?.last_row_id;
        const pct = retail && price ? ` (${Math.round((1 - price / retail) * 100)}% off)` : "";
        return discordReply(`\u2705 eBay deal posted (#${id}): **${title}**${pct}${featured ? " \u2B50 featured" : ""}`);
      } catch (e) {
        return discordReply(`\u274C DB error: ${e.message}`);
      }
    }
    if (cmd === "recent") return handleDiscordRecent(options, env);
    if (cmd === "delete") return handleDiscordDelete(options, env);
    return discordReply(`\u2753 Unknown command: ${cmd}`);
  }
  return new Response("Unhandled interaction type", { status: 400 });
}
__name(handleDiscord, "handleDiscord");
function buildAmazonAffiliateLink(rawUrl) {
  const u = new URL(rawUrl);
  u.searchParams.set("tag", AMAZON_TAG);
  return u.toString();
}
__name(buildAmazonAffiliateLink, "buildAmazonAffiliateLink");
function buildEbayAffiliateLink(rawUrl) {
  const u = new URL(rawUrl);
  u.searchParams.set("mkevt", "1");
  u.searchParams.set("mkcid", "1");
  u.searchParams.set("toolid", "10001");
  u.searchParams.set("customid", "ebaydeal");
  if (EBAY_CAMPAIGN_ID) u.searchParams.set("campid", EBAY_CAMPAIGN_ID);
  return u.toString();
}
__name(buildEbayAffiliateLink, "buildEbayAffiliateLink");
async function handleDealsGet(url, env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  const limit = Math.min(parseInt(url.searchParams.get("limit") || "20"), 50);
  const now = Date.now();
  try {
    const rows = await env.PRICE_CACHE.prepare(`
      SELECT * FROM deals
      WHERE expires_at IS NULL OR expires_at > ?
      ORDER BY created_at DESC
      LIMIT ?
    `).bind(now, limit).all();
    const deals = (rows.results || []).map((r) => ({
      id: r.deal_id || String(r.id),
      title: r.title,
      setNum: r.set_num,
      retailPrice: r.retail_price,
      dealPrice: r.deal_price,
      retailer: r.retailer,
      url: r.url,
      imageUrl: r.image_url,
      note: r.note,
      featured: r.featured === 1,
      expires: r.expires_at ? new Date(r.expires_at).toISOString().slice(0, 10) : null
    }));
    return json({ deals });
  } catch (e) {
    return err(`DB error: ${e.message}`, 500);
  }
}
__name(handleDealsGet, "handleDealsGet");
async function handleDealsAdd(request, env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  const secret = request.headers.get("x-brikstax-secret");
  if (secret !== (env.NEWS_SECRET || "brikstax2026")) return err("Unauthorized", 401);
  let body;
  try {
    body = await request.json();
  } catch {
    return err("Invalid JSON");
  }
  const { id, title, setNum, retailPrice, dealPrice, retailer, url, imageUrl, note, featured, expiresDays } = body;
  if (!title || !url) return err("Missing title or url");
  const days = expiresDays != null ? expiresDays : 30;
  const expires_at = Date.now() + days * 24 * 60 * 60 * 1e3;
  try {
    const result = await env.PRICE_CACHE.prepare(`
      INSERT INTO deals
        (deal_id, title, set_num, retail_price, deal_price,
         retailer, url, image_url, note, featured, expires_at, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      id || null,
      title,
      setNum || null,
      retailPrice != null ? retailPrice : null,
      dealPrice != null ? dealPrice : null,
      retailer || null,
      url,
      imageUrl || null,
      note || null,
      featured ? 1 : 0,
      expires_at,
      Date.now()
    ).run();
    return json({ ok: true, id: result.meta?.last_row_id });
  } catch (e) {
    return err(`DB error: ${e.message}`, 500);
  }
}
__name(handleDealsAdd, "handleDealsAdd");
async function handleDealsClear(request, env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  const secret = request.headers.get("x-brikstax-secret");
  if (secret !== (env.NEWS_SECRET || "brikstax2026")) return err("Unauthorized", 401);
  let body;
  try {
    body = await request.json();
  } catch {
    body = {};
  }
  try {
    if (body.mode === "all") {
      const r2 = await env.PRICE_CACHE.prepare("DELETE FROM deals").run();
      return json({ ok: true, deleted: r2.meta?.changes ?? 0 });
    }
    const r = await env.PRICE_CACHE.prepare(
      "DELETE FROM deals WHERE expires_at IS NOT NULL AND expires_at < ?"
    ).bind(Date.now()).run();
    return json({ ok: true, deleted: r.meta?.changes ?? 0 });
  } catch (e) {
    return err(`DB error: ${e.message}`, 500);
  }
}
__name(handleDealsClear, "handleDealsClear");
async function discoverNewSets(env) {
  const progress = await env.PRICE_CACHE.prepare(
    "SELECT rb_page, rb_done FROM seed_progress WHERE id = 1"
  ).first();
  if (progress?.rb_done === 1) {
    await env.PRICE_CACHE.prepare(
      "UPDATE seed_progress SET rb_page = 1, rb_done = 0 WHERE id = 1"
    ).run();
  }
  const page = progress?.rb_page || 1;
  try {
    const rbUrl = `https://rebrickable.com/api/v3/lego/sets/?ordering=-year&page_size=${RB_DISCOVERY_PAGE_SIZE}&page=${page}&min_parts=10`;
    const resp = await rbFetch(rbUrl, env);
    if (!resp.ok) return { discovered: 0, error: `HTTP ${resp.status}` };
    const data = await resp.json();
    const results = data.results || [];
    if (results.length === 0) {
      await env.PRICE_CACHE.prepare("UPDATE seed_progress SET rb_done = 1 WHERE id = 1").run();
      return { discovered: 0, done: true };
    }
    let added = 0;
    for (const set of results) {
      const setNum = (set.set_num || "").replace(/-\d+$/, "");
      if (!setNum) continue;
      if (set.year && set.year < MIN_YEAR) continue;
      if (!/^\d{3,7}$/.test(setNum)) continue;
      const existing = await env.PRICE_CACHE.prepare(
        "SELECT barcode FROM barcode_cache WHERE set_num = ? LIMIT 1"
      ).bind(setNum).first();
      if (existing) continue;
      try {
        await env.PRICE_CACHE.prepare(`
          INSERT INTO seed_queue (set_num, set_name, queued_at)
          VALUES (?, ?, ?)
          ON CONFLICT(set_num) DO NOTHING
        `).bind(setNum, set.name || null, Date.now()).run();
        added++;
      } catch (_) {
      }
    }
    await env.PRICE_CACHE.prepare("UPDATE seed_progress SET rb_page = ? WHERE id = 1").bind(page + 1).run();
    return { discovered: added, page, total_found: results.length };
  } catch (e) {
    return { discovered: 0, error: e.message };
  }
}
__name(discoverNewSets, "discoverNewSets");
async function getNextSeedBatch(env, limit) {
  const rows = await env.PRICE_CACHE.prepare(
    "SELECT set_num, set_name FROM seed_queue ORDER BY queued_at ASC LIMIT ?"
  ).bind(limit).all();
  return (rows.results || []).map((r) => ({ n: r.set_num, name: r.set_name }));
}
__name(getNextSeedBatch, "getNextSeedBatch");
async function removeFromQueue(env, setNum) {
  try {
    await env.PRICE_CACHE.prepare("DELETE FROM seed_queue WHERE set_num = ?").bind(setNum).run();
  } catch (_) {
  }
}
__name(removeFromQueue, "removeFromQueue");
async function logSeedError(env, setNum, msg) {
  try {
    await env.PRICE_CACHE.prepare(
      "INSERT INTO seed_errors (set_num, error_msg, occurred_at) VALUES (?, ?, ?)"
    ).bind(setNum, msg, Date.now()).run();
  } catch (_) {
  }
}
__name(logSeedError, "logSeedError");
var sleep = /* @__PURE__ */ __name((ms) => new Promise((r) => setTimeout(r, ms)), "sleep");
async function ensureMonthlyCatchupColumn(env) {
  try {
    await env.PRICE_CACHE.prepare(
      "ALTER TABLE seed_progress ADD COLUMN monthly_catchup_month TEXT"
    ).run();
  } catch (_) {
  }
}
__name(ensureMonthlyCatchupColumn, "ensureMonthlyCatchupColumn");
async function runMonthlyCatchup(env, limit) {
  const candidates = [];
  for (let page = 1; page <= MONTHLY_CATCHUP_PAGES && candidates.length < limit; page++) {
    try {
      const rbUrl = `https://rebrickable.com/api/v3/lego/sets/?ordering=-year&page_size=${RB_DISCOVERY_PAGE_SIZE}&page=${page}&min_parts=10`;
      const resp = await rbFetch(rbUrl, env);
      if (!resp.ok) break;
      const data = await resp.json();
      const results = data.results || [];
      if (results.length === 0) break;
      for (const set of results) {
        if (candidates.length >= limit) break;
        const setNum = (set.set_num || "").replace(/-\d+$/, "");
        if (!setNum || !/^\d{3,7}$/.test(setNum)) continue;
        if (set.year && set.year < MIN_YEAR) continue;
        try {
          const existing = await env.PRICE_CACHE.prepare(
            "SELECT barcode FROM barcode_cache WHERE set_num = ? LIMIT 1"
          ).bind(setNum).first();
          if (existing) continue;
        } catch (_) {
        }
        candidates.push({ n: setNum, name: set.name || null });
      }
    } catch (e) {
      break;
    }
  }
  return candidates;
}
__name(runMonthlyCatchup, "runMonthlyCatchup");
async function runSeedBatch(env) {
  if (!env.PRICE_CACHE) return { ok: false, reason: "no_db" };
  await ensureMonthlyCatchupColumn(env);
  const bsKey = env.BRICKSET_KEY || BRICKSET_KEY_FALLBACK;
  const now = /* @__PURE__ */ new Date();
  const monthKey = now.toISOString().slice(0, 7);
  const dayOfMonth = now.getUTCDate();
  let monthlyCatchup = false;
  let batch;
  let discoveryResult = null;
  const progress = await env.PRICE_CACHE.prepare(
    "SELECT monthly_catchup_month FROM seed_progress WHERE id = 1"
  ).first();
  const alreadyCaughtUpThisMonth = progress?.monthly_catchup_month === monthKey;
  if (dayOfMonth <= MONTHLY_CATCHUP_DAY_CUTOFF && !alreadyCaughtUpThisMonth) {
    monthlyCatchup = true;
    batch = await runMonthlyCatchup(env, DAILY_SEED_LIMIT);
    await env.PRICE_CACHE.prepare(
      "UPDATE seed_progress SET monthly_catchup_month = ? WHERE id = 1"
    ).bind(monthKey).run();
  } else {
    const queueCount = await env.PRICE_CACHE.prepare("SELECT COUNT(*) as cnt FROM seed_queue").first();
    let currentQueueSize = queueCount?.cnt ?? 0;
    let attempts = 0;
    while (currentQueueSize < DAILY_SEED_LIMIT * 2 && attempts < 3) {
      discoveryResult = await discoverNewSets(env);
      attempts++;
      if (!discoveryResult || discoveryResult.done || (discoveryResult.discovered ?? 0) === 0) break;
      const recount = await env.PRICE_CACHE.prepare("SELECT COUNT(*) as cnt FROM seed_queue").first();
      currentQueueSize = recount?.cnt ?? 0;
    }
    batch = await getNextSeedBatch(env, DAILY_SEED_LIMIT);
  }
  if (batch.length === 0) return { ok: true, seeded: 0, skipped: 0, errors: 0, processed: 0, queue_empty: true, discovery: discoveryResult, monthly_catchup: monthlyCatchup };
  let seeded = 0, skipped = 0, errors = 0, processed = 0;
  for (const set of batch) {
    processed++;
    try {
      const existing = await env.PRICE_CACHE.prepare("SELECT barcode FROM barcode_cache WHERE set_num = ? LIMIT 1").bind(set.n).first();
      if (existing) {
        skipped++;
        await removeFromQueue(env, set.n);
        continue;
      }
    } catch (_) {
    }
    try {
      const params = JSON.stringify({ setNumber: `${set.n}-1`, pageSize: 1 });
      const bsUrl = `https://brickset.com/api/v3.asmx/getSets?apiKey=${encodeURIComponent(bsKey)}&userHash=&params=${encodeURIComponent(params)}`;
      const resp = await fetch(bsUrl, { headers: { "User-Agent": "BrikStax/2.4", "Accept": "application/json" } });
      if (!resp.ok) {
        await logSeedError(env, set.n, `HTTP ${resp.status}`);
        errors++;
        await removeFromQueue(env, set.n);
        await sleep(BRICKSET_DELAY_MS);
        continue;
      }
      const text = await resp.text();
      const ji = text.indexOf("{");
      if (ji < 0) {
        await logSeedError(env, set.n, "No JSON");
        errors++;
        await removeFromQueue(env, set.n);
        await sleep(BRICKSET_DELAY_MS);
        continue;
      }
      const d = JSON.parse(text.substring(ji));
      const sets = d.sets || [];
      if (sets.length === 0) {
        skipped++;
        await removeFromQueue(env, set.n);
        await sleep(BRICKSET_DELAY_MS);
        continue;
      }
      const s = sets[0];
      const upc = s.barcode?.UPC || null;
      const ean = s.barcode?.EAN || null;
      if (!upc && !ean) {
        skipped++;
        await removeFromQueue(env, set.n);
        await sleep(BRICKSET_DELAY_MS);
        continue;
      }
      const stmt = env.PRICE_CACHE.prepare(`
        INSERT INTO barcode_cache (barcode, set_num, set_name, cached_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(barcode) DO UPDATE SET
          set_num = excluded.set_num, set_name = excluded.set_name, cached_at = excluded.cached_at
      `);
      const name = s.name || set.name;
      if (upc) await stmt.bind(upc, set.n, name, Date.now()).run();
      if (ean) await stmt.bind(ean, set.n, name, Date.now()).run();
      seeded++;
      await removeFromQueue(env, set.n);
    } catch (e) {
      await logSeedError(env, set.n, e.message || "unknown");
      errors++;
      await removeFromQueue(env, set.n);
    }
    await sleep(BRICKSET_DELAY_MS);
  }
  await env.PRICE_CACHE.prepare("UPDATE seed_progress SET last_run = ? WHERE id = 1").bind((/* @__PURE__ */ new Date()).toISOString()).run();
  const remaining = await env.PRICE_CACHE.prepare("SELECT COUNT(*) as cnt FROM seed_queue").first();
  return { ok: true, seeded, skipped, errors, processed, queue_remaining: remaining?.cnt ?? 0, discovery: discoveryResult, monthly_catchup: monthlyCatchup };
}
__name(runSeedBatch, "runSeedBatch");
async function handleSeedStatus(env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  try {
    const progress = await env.PRICE_CACHE.prepare("SELECT * FROM seed_progress WHERE id = 1").first();
    const barcodeCount = await env.PRICE_CACHE.prepare("SELECT COUNT(*) as cnt FROM barcode_cache").first();
    const queueCount = await env.PRICE_CACHE.prepare("SELECT COUNT(*) as cnt FROM seed_queue").first();
    const nextSet = await env.PRICE_CACHE.prepare("SELECT set_num FROM seed_queue ORDER BY queued_at ASC LIMIT 1").first();
    return json({ mode: "dynamic", barcodes_cached: barcodeCount?.cnt ?? 0, queue_size: queueCount?.cnt ?? 0, rebrickable_page: progress?.rb_page ?? 1, rebrickable_exhausted: progress?.rb_done === 1, last_run: progress?.last_run ?? "never", next_set: nextSet?.set_num ?? null, monthly_catchup_month: progress?.monthly_catchup_month ?? null });
  } catch (e) {
    return err(`DB error: ${e.message}`);
  }
}
__name(handleSeedStatus, "handleSeedStatus");
async function handleSeedRun(env) {
  return json(await runSeedBatch(env));
}
__name(handleSeedRun, "handleSeedRun");
async function handleSeedErrors(env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  try {
    const rows = await env.PRICE_CACHE.prepare("SELECT * FROM seed_errors ORDER BY occurred_at DESC LIMIT 30").all();
    return json({ errors: rows.results || [] });
  } catch (e) {
    return err(`DB error: ${e.message}`, 500);
  }
}
__name(handleSeedErrors, "handleSeedErrors");
async function handleBarcodeCache(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    return err("Invalid JSON");
  }
  const { ean, set_num, set_name } = body;
  if (!ean || !set_num) return err("Missing ean or set_num");
  if (!env.PRICE_CACHE) return json({ ok: false, reason: "no_db" });
  try {
    await env.PRICE_CACHE.prepare(`
      INSERT INTO barcode_cache (barcode, set_num, set_name, cached_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(barcode) DO UPDATE SET
        set_num = excluded.set_num, set_name = excluded.set_name, cached_at = excluded.cached_at
    `).bind(ean, set_num, set_name || null, Date.now()).run();
    return json({ ok: true, ean, set_num });
  } catch (e) {
    return err(`DB error: ${e.message}`, 500);
  }
}
__name(handleBarcodeCache, "handleBarcodeCache");
async function handleBarcode(url, env) {
  const ean = url.searchParams.get("ean");
  if (!ean) return err("Missing ean param");
  if (env.PRICE_CACHE) {
    try {
      const row = await env.PRICE_CACHE.prepare("SELECT * FROM barcode_cache WHERE barcode = ?").bind(ean).first();
      if (row) {
        const ageMs = Date.now() - row.cached_at;
        if (ageMs < BARCODE_CACHE_TTL_DAYS * 864e5)
          return json({ source: "cache", barcode: ean, set_num: row.set_num, set_name: row.set_name });
      }
    } catch (e) {
      console.error("D1 barcode read:", e.message);
    }
  }
  let setNum = null, setName = null;
  const urls = [`https://rebrickable.com/api/v3/lego/sets/?search=${ean}&page_size=1`];
  if (ean.length === 12) urls.push(`https://rebrickable.com/api/v3/lego/sets/?search=0${ean}&page_size=1`);
  for (const rbUrl of urls) {
    try {
      const resp = await rbFetch(rbUrl, env);
      if (resp.ok) {
        const d = await resp.json();
        if (d.results?.length > 0) {
          setNum = (d.results[0].set_num || "").replace(/-\d+$/, "");
          setName = d.results[0].name || null;
          break;
        }
      }
    } catch (e) {
      console.error("Rebrickable search:", e.message);
    }
  }
  if (!setNum) return json({ found: false, barcode: ean }, 404);
  if (env.PRICE_CACHE) {
    try {
      await env.PRICE_CACHE.prepare(`
        INSERT INTO barcode_cache (barcode, set_num, set_name, cached_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(barcode) DO UPDATE SET
          set_num = excluded.set_num, set_name = excluded.set_name, cached_at = excluded.cached_at
      `).bind(ean, setNum, setName, Date.now()).run();
    } catch (e) {
      console.error("D1 barcode write:", e.message);
    }
  }
  return json({ source: "rebrickable", barcode: ean, set_num: setNum, set_name: setName });
}
__name(handleBarcode, "handleBarcode");
async function handleBarcodeSubmit(request, env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  let body;
  try {
    body = await request.json();
  } catch {
    return err("Invalid JSON");
  }
  const { barcode, set_num, user_id } = body;
  if (!barcode || !set_num || !user_id) {
    return err("Missing barcode, set_num, or user_id");
  }
  const cleanSetNum = String(set_num).replace(/-\d+$/, "").trim();
  const cleanBarcode = String(barcode).trim();
  try {
    await env.PRICE_CACHE.prepare(`
      INSERT INTO barcode_submissions (barcode, set_num, user_id, submitted_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(barcode, user_id) DO UPDATE SET
        set_num = excluded.set_num, submitted_at = excluded.submitted_at
    `).bind(cleanBarcode, cleanSetNum, user_id, Date.now()).run();
  } catch (e) {
    return err("DB error: " + e.message, 500);
  }
  let agreeCount = 0;
  try {
    const result = await env.PRICE_CACHE.prepare(`
      SELECT COUNT(DISTINCT user_id) as cnt FROM barcode_submissions
      WHERE barcode = ? AND set_num = ?
    `).bind(cleanBarcode, cleanSetNum).first();
    agreeCount = result?.cnt ?? 0;
  } catch (e) {
    console.error("Consensus count failed:", e.message);
  }
  const CONSENSUS_THRESHOLD = 2;
  let promoted = false;
  if (agreeCount >= CONSENSUS_THRESHOLD) {
    let setName = null;
    try {
      const resp = await rbFetch(`sets/${cleanSetNum}-1/`, env);
      if (resp.ok) {
        const d = await resp.json();
        setName = d.name || null;
      }
    } catch (e) {
      console.error("Rebrickable lookup for promotion failed:", e.message);
    }
    try {
      await env.PRICE_CACHE.prepare(`
        INSERT INTO barcode_cache (barcode, set_num, set_name, cached_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(barcode) DO UPDATE SET
          set_num = excluded.set_num, set_name = excluded.set_name, cached_at = excluded.cached_at
      `).bind(cleanBarcode, cleanSetNum, setName, Date.now()).run();
      promoted = true;
    } catch (e) {
      console.error("Promotion to barcode_cache failed:", e.message);
    }
  }
  return json({
    ok: true,
    agree_count: agreeCount,
    threshold: CONSENSUS_THRESHOLD,
    promoted
  });
}
__name(handleBarcodeSubmit, "handleBarcodeSubmit");
async function handleProxy(url) {
  const target = url.searchParams.get("url");
  if (!target) return err("Missing url param");
  const allowed = ALLOWED.some((a) => target.includes(a));
  if (!allowed) return err(`Domain not allowed`, 403);
  try {
    const resp = await fetch(target, { headers: { "User-Agent": "BrikStax/2.4", "Accept": "application/json" } });
    const body = await resp.text();
    return new Response(body, { status: resp.status, headers: { "Content-Type": "application/json", ...CORS } });
  } catch (e) {
    return err(`Proxy error: ${e.message}`, 502);
  }
}
__name(handleProxy, "handleProxy");
async function handleEbay(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    return err("Invalid JSON body");
  }
  const { num, condition, name } = body;
  if (!num || !condition) return err("Missing num or condition");
  const cacheKey = `${num}:${condition}`;
  if (env.PRICE_CACHE) {
    try {
      const row = await env.PRICE_CACHE.prepare("SELECT * FROM price_cache WHERE cache_key = ?").bind(cacheKey).first();
      if (row) {
        const ageMs = Date.now() - row.fetched_at;
        if (ageMs < EBAY_CACHE_TTL_DAYS * 864e5)
          return json({ source: "cache", age_hours: Math.round(ageMs / 36e5), avg: row.avg_price, median: row.median_price, min: row.min_price, max: row.max_price, count: row.listing_count, fetched_at: row.fetched_at });
      }
    } catch (e) {
      console.error("D1 eBay read:", e.message);
    }
  }
  const monthKey = (/* @__PURE__ */ new Date()).toISOString().slice(0, 7);
  const EBAY_MONTHLY_CAP = 1350;
  if (env.PRICE_CACHE) {
    try {
      const usage = await env.PRICE_CACHE.prepare(
        "SELECT call_count FROM ebay_usage WHERE month_key = ?"
      ).bind(monthKey).first();
      if (usage && usage.call_count >= EBAY_MONTHLY_CAP) {
        return err("ebay_monthly_cap_reached", 429);
      }
    } catch (e) {
      console.error("ebay_usage check failed:", e.message);
    }
  }
  const ebayKey = env.EBAY_KEY;
  if (!ebayKey) return err("eBay API key not configured", 500);
  const sealed = condition === "sealed";
  const keywords = `LEGO ${num}${name ? " " + name : ""}`;
  const excluded = sealed ? "instructions manual only parts lot bulk custom opened used displayed built" : "sealed NIB MISB unopened factory-sealed";
  let ebayData;
  try {
    const resp = await fetch(`https://${EBAY_HOST}/findCompletedItems`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-rapidapi-key": ebayKey, "x-rapidapi-host": EBAY_HOST },
      body: JSON.stringify({ keywords, excluded_keywords: excluded, max_search_results: "120", remove_outliers: "true", site_id: "0", category_id: "19006" })
    });
    if (resp.status === 403) return err("not_subscribed", 403);
    if (resp.status === 429) return err("rate_limited", 429);
    if (!resp.ok) return err(`eBay HTTP ${resp.status}`, 502);
    const d = await resp.json();
    ebayData = { avg: parseFloat(d.average_price) || null, median: parseFloat(d.median_price) || null, min: parseFloat(d.min_price) || null, max: parseFloat(d.max_price) || null, count: parseInt(d.results_count) || 0 };
  } catch (e) {
    return err(`eBay fetch failed: ${e.message}`, 502);
  }
  if (env.PRICE_CACHE) {
    try {
      await env.PRICE_CACHE.prepare(`
        INSERT INTO ebay_usage (month_key, call_count, updated_at)
        VALUES (?, 1, ?)
        ON CONFLICT(month_key) DO UPDATE SET
          call_count = call_count + 1, updated_at = excluded.updated_at
      `).bind(monthKey, Date.now()).run();
    } catch (e) {
      console.error("ebay_usage increment failed:", e.message);
    }
  }
  if (env.PRICE_CACHE && ebayData.avg !== null) {
    try {
      await env.PRICE_CACHE.prepare(`
        INSERT INTO price_cache (cache_key, set_num, condition, avg_price, median_price, min_price, max_price, listing_count, fetched_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(cache_key) DO UPDATE SET avg_price = excluded.avg_price, median_price = excluded.median_price, min_price = excluded.min_price, max_price = excluded.max_price, listing_count = excluded.listing_count, fetched_at = excluded.fetched_at
      `).bind(cacheKey, num, condition, ebayData.avg, ebayData.median, ebayData.min, ebayData.max, ebayData.count, Date.now()).run();
    } catch (e) {
      console.error("D1 eBay write:", e.message);
    }
  }
  return json({ source: "live", age_hours: 0, ...ebayData, fetched_at: Date.now() });
}
__name(handleEbay, "handleEbay");
async function handleEbayUsage(env) {
  const monthKey = (/* @__PURE__ */ new Date()).toISOString().slice(0, 7);
  const EBAY_MONTHLY_CAP = 1350;
  let calls = 0;
  if (env.PRICE_CACHE) {
    try {
      const row = await env.PRICE_CACHE.prepare(
        "SELECT call_count FROM ebay_usage WHERE month_key = ?"
      ).bind(monthKey).first();
      calls = row?.call_count ?? 0;
    } catch (e) {
      console.error("ebay usage read failed:", e.message);
    }
  }
  return json({ month: monthKey, calls, cap: EBAY_MONTHLY_CAP, blocked: calls >= EBAY_MONTHLY_CAP });
}
__name(handleEbayUsage, "handleEbayUsage");
async function checkEbayCache(url, env) {
  const num = url.searchParams.get("num");
  const condition = url.searchParams.get("condition");
  if (!num || !condition) return err("Missing num or condition");
  if (!env.PRICE_CACHE) return json({ cached: false });
  try {
    const row = await env.PRICE_CACHE.prepare("SELECT * FROM price_cache WHERE cache_key = ?").bind(`${num}:${condition}`).first();
    if (!row) return json({ cached: false });
    const ageMs = Date.now() - row.fetched_at;
    return json({ cached: true, stale: ageMs >= EBAY_CACHE_TTL_DAYS * 864e5, age_hours: Math.round(ageMs / 36e5), avg: row.avg_price, median: row.median_price, min: row.min_price, max: row.max_price, count: row.listing_count, fetched_at: row.fetched_at });
  } catch (e) {
    return err(`DB error: ${e.message}`, 500);
  }
}
__name(checkEbayCache, "checkEbayCache");
async function handleDebug(url, env) {
  const bsKey = env.BRICKSET_KEY || BRICKSET_KEY_FALLBACK;
  const setNum = url.searchParams.get("set") || "75192";
  const results = {};
  try {
    const p = JSON.stringify({ setNumber: `${setNum}-1`, pageSize: 1 });
    const u = `https://brickset.com/api/v3.asmx/getSets?apiKey=${encodeURIComponent(bsKey)}&userHash=&params=${encodeURIComponent(p)}`;
    const r = await fetch(u);
    results.brickset = { status: r.status, body: await r.text() };
  } catch (e) {
    results.brickset = { error: e.message };
  }
  try {
    const ebayKey = env.EBAY_KEY;
    if (!ebayKey) {
      results.ebay = { error: "EBAY_KEY not set" };
    } else {
      const resp = await fetch(`https://${EBAY_HOST}/findCompletedItems`, {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-rapidapi-key": ebayKey, "x-rapidapi-host": EBAY_HOST },
        body: JSON.stringify({ keywords: `LEGO ${setNum} sealed NIB new`, excluded_keywords: "instructions manual parts lot bulk custom open used", max_search_results: "60", remove_outliers: "true", site_id: "0", category_id: "19006" })
      });
      results.ebay = { status: resp.status, body: await resp.text() };
    }
  } catch (e) {
    results.ebay = { error: e.message };
  }
  return json({ debug: true, set: setNum, results });
}
__name(handleDebug, "handleDebug");
async function handleCommunitySubmit(request, env, ctx) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  if (!env.COMMUNITY_PHOTOS) return err("No R2 binding");
  let formData;
  try {
    formData = await request.formData();
  } catch (e) {
    return err("Invalid form data: " + e.message);
  }
  const userId = formData.get("user_id");
  const caption = formData.get("caption") || null;
  const setNum = formData.get("set_num") || null;
  const file = formData.get("image");
  const devMode = formData.get("dev_mode") === "1";
  if (!userId) return err("Missing user_id");
  if (!file || typeof file === "string") return err("Missing image file");
  if (!file.type || !file.type.startsWith("image/")) {
    return err("File must be an image");
  }
  if (file.size > 10 * 1024 * 1024) {
    return err("Image too large (max 10MB)", 413);
  }
  if (!devMode) {
    try {
      const isTrusted = await env.PRICE_CACHE.prepare(
        "SELECT user_id FROM trusted_users WHERE user_id = ?"
      ).bind(userId).first();
      const cooldownMs = isTrusted ? TRUSTED_SUBMIT_COOLDOWN_MS : COMMUNITY_SUBMIT_COOLDOWN_MS;
      const lastPost = await env.PRICE_CACHE.prepare(`
        SELECT submitted_at FROM community_posts
        WHERE user_id = ?
        ORDER BY submitted_at DESC
        LIMIT 1
      `).bind(userId).first();
      if (lastPost) {
        const elapsed = Date.now() - lastPost.submitted_at;
        if (elapsed < cooldownMs) {
          const retryAfterMs = cooldownMs - elapsed;
          return json({
            error: "rate_limited",
            retry_after_seconds: Math.ceil(retryAfterMs / 1e3),
            trusted: !!isTrusted
          }, 429);
        }
      }
    } catch (e) {
      console.error("Rate limit check failed:", e.message);
    }
  }
  const ext = (file.type.split("/")[1] || "jpg").replace("jpeg", "jpg");
  const key = `pending/${Date.now()}-${crypto.randomUUID()}.${ext}`;
  try {
    await env.COMMUNITY_PHOTOS.put(key, file.stream(), {
      httpMetadata: { contentType: file.type }
    });
  } catch (e) {
    return err("Upload to storage failed: " + e.message, 502);
  }
  let postId;
  try {
    const result = await env.PRICE_CACHE.prepare(`
      INSERT INTO community_posts (user_id, image_key, caption, set_num, status, submitted_at)
      VALUES (?, ?, ?, ?, 'pending', ?)
    `).bind(userId, key, caption, setNum, Date.now()).run();
    postId = result.meta?.last_row_id;
  } catch (e) {
    await env.COMMUNITY_PHOTOS.delete(key).catch(() => {
    });
    return err("DB error: " + e.message, 500);
  }
  if (env.MOD_WEBHOOK_URL) {
    const notifyPromise = notifyModChannel(env, postId, key, userId, caption, setNum).catch((e) => console.error("Mod notify failed:", e.message));
    if (ctx && ctx.waitUntil) {
      ctx.waitUntil(notifyPromise);
    } else {
      await notifyPromise;
    }
  }
  return json({ ok: true, id: postId, status: "pending" });
}
__name(handleCommunitySubmit, "handleCommunitySubmit");
async function notifyModChannel(env, postId, imageKey, userId, caption, setNum) {
  const MOD_CHANNEL_ID = "1518832709378510878";
  const imageUrl = `${env.PUBLIC_WORKER_URL || "https://brikstax-worker.paul-olsen1684.workers.dev"}/community/photo/${encodeURIComponent(imageKey)}`;
  const embed = {
    title: `New submission #${postId}`,
    description: caption || "(no caption)",
    fields: [
      { name: "User", value: userId, inline: true },
      { name: "Set", value: setNum || "\u2014", inline: true }
    ],
    image: { url: imageUrl },
    color: 16763648
  };
  const components = [{
    type: 1,
    components: [
      {
        type: 2,
        style: 3,
        // green
        label: "Approve",
        custom_id: `mod_approve:${postId}`
      },
      {
        type: 2,
        style: 4,
        // red
        label: "Reject",
        custom_id: `mod_reject:${postId}`
      }
    ]
  }];
  if (!env.DISCORD_BOT_TOKEN) {
    console.error("No DISCORD_BOT_TOKEN \u2014 cannot post mod notification with buttons");
    return { status: 0, body: "no bot token configured" };
  }
  const res = await fetch(
    `https://discord.com/api/v10/channels/${MOD_CHANNEL_ID}/messages`,
    {
      method: "POST",
      headers: {
        "Authorization": `Bot ${env.DISCORD_BOT_TOKEN}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        // Bot-sent messages with an @mention DO trigger a real push
        // notification, same as the webhook version did once we added
        // the mention there too.
        content: "<@285276700562948106> New submission to review:",
        embeds: [embed],
        components,
        allowed_mentions: { users: ["285276700562948106"] }
      })
    }
  );
  const bodyText = await res.text().catch(() => "(no body)");
  console.log(`Mod notification post response: ${res.status} \u2014 ${bodyText}`);
  if (!res.ok) {
    throw new Error(`Discord bot message failed: ${res.status} ${bodyText}`);
  }
  return { status: res.status, body: bodyText };
}
__name(notifyModChannel, "notifyModChannel");
async function handleCommunityPhoto(url, env) {
  if (!env.COMMUNITY_PHOTOS) return err("No R2 binding");
  const key = decodeURIComponent(url.pathname.replace("/community/photo/", ""));
  if (!key) return err("Missing photo key");
  const obj = await env.COMMUNITY_PHOTOS.get(key);
  if (!obj) return err("Photo not found", 404);
  return new Response(obj.body, {
    headers: {
      "Content-Type": obj.httpMetadata?.contentType || "image/jpeg",
      "Cache-Control": "public, max-age=31536000",
      ...CORS
    }
  });
}
__name(handleCommunityPhoto, "handleCommunityPhoto");
async function handleCommunityFeed(url, env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  const limit = Math.min(parseInt(url.searchParams.get("limit") || "20"), 50);
  const userId = url.searchParams.get("user_id");
  try {
    const rows = await env.PRICE_CACHE.prepare(`
      SELECT id, user_id, image_key, caption, set_num, submitted_at
      FROM community_posts
      WHERE status = 'approved'
      ORDER BY submitted_at DESC
      LIMIT ?
    `).bind(limit).all();
    const postRows = rows.results || [];
    const ids = postRows.map((r) => r.id);
    let counts = {};
    let likedSet = /* @__PURE__ */ new Set();
    if (ids.length > 0) {
      const placeholders = ids.map(() => "?").join(",");
      const countRows = await env.PRICE_CACHE.prepare(`
        SELECT post_id, COUNT(*) as cnt FROM community_likes
        WHERE post_id IN (${placeholders})
        GROUP BY post_id
      `).bind(...ids).all();
      for (const r of countRows.results || []) counts[r.post_id] = r.cnt;
      if (userId) {
        const likedRows = await env.PRICE_CACHE.prepare(`
          SELECT post_id FROM community_likes
          WHERE user_id = ? AND post_id IN (${placeholders})
        `).bind(userId, ...ids).all();
        likedSet = new Set((likedRows.results || []).map((r) => r.post_id));
      }
    }
    const posts = postRows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      imageUrl: `${env.PUBLIC_WORKER_URL || "https://brikstax-worker.paul-olsen1684.workers.dev"}/community/photo/${encodeURIComponent(r.image_key)}`,
      caption: r.caption,
      setNum: r.set_num,
      submittedAt: r.submitted_at,
      likeCount: counts[r.id] || 0,
      likedByMe: likedSet.has(r.id)
    }));
    return json({ posts });
  } catch (e) {
    return err("DB error: " + e.message, 500);
  }
}
__name(handleCommunityFeed, "handleCommunityFeed");
async function handleCommunityLike(request, env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  let body;
  try {
    body = await request.json();
  } catch {
    return err("Invalid JSON");
  }
  const postId = body.post_id;
  const userId = body.user_id;
  if (!postId || !userId) return err("Missing post_id or user_id");
  try {
    const post = await env.PRICE_CACHE.prepare(
      `SELECT id FROM community_posts WHERE id = ? AND status = 'approved'`
    ).bind(postId).first();
    if (!post) return err("Post not found", 404);
    const existing = await env.PRICE_CACHE.prepare(
      "SELECT id FROM community_likes WHERE post_id = ? AND user_id = ?"
    ).bind(postId, userId).first();
    let liked;
    if (existing) {
      await env.PRICE_CACHE.prepare(
        "DELETE FROM community_likes WHERE id = ?"
      ).bind(existing.id).run();
      liked = false;
    } else {
      await env.PRICE_CACHE.prepare(
        "INSERT INTO community_likes (post_id, user_id, created_at) VALUES (?, ?, ?)"
      ).bind(postId, userId, Date.now()).run();
      liked = true;
    }
    const countRow = await env.PRICE_CACHE.prepare(
      "SELECT COUNT(*) as cnt FROM community_likes WHERE post_id = ?"
    ).bind(postId).first();
    return json({ liked, likeCount: countRow?.cnt || 0 });
  } catch (e) {
    return err("DB error: " + e.message, 500);
  }
}
__name(handleCommunityLike, "handleCommunityLike");
async function handlePushRegister(request, env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  let body;
  try {
    body = await request.json();
  } catch {
    return err("Invalid JSON");
  }
  const { user_id, token, platform } = body;
  if (!user_id || !token) return err("Missing user_id or token");
  try {
    await env.PRICE_CACHE.prepare(`
      INSERT INTO push_tokens (user_id, token, platform, updated_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(user_id) DO UPDATE SET
        token = excluded.token,
        platform = excluded.platform,
        updated_at = excluded.updated_at
    `).bind(user_id, token, platform || "android", Date.now()).run();
    return json({ ok: true });
  } catch (e) {
    return err("DB error: " + e.message, 500);
  }
}
__name(handlePushRegister, "handlePushRegister");
var _fcmTokenCache = { accessToken: null, expiresAt: 0 };
function base64UrlFromBytes(bytes) {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
__name(base64UrlFromBytes, "base64UrlFromBytes");
function base64UrlFromString(str) {
  return base64UrlFromBytes(new TextEncoder().encode(str));
}
__name(base64UrlFromString, "base64UrlFromString");
function pemToDer(pem) {
  const b64 = pem.replace(/-----BEGIN PRIVATE KEY-----/, "").replace(/-----END PRIVATE KEY-----/, "").replace(/\s+/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}
__name(pemToDer, "pemToDer");
async function getFirebaseAccessToken(env) {
  const now = Date.now();
  if (_fcmTokenCache.accessToken && _fcmTokenCache.expiresAt > now + 6e4) {
    return _fcmTokenCache.accessToken;
  }
  if (!env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON not configured");
  }
  const sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON);
  const header = { alg: "RS256", typ: "JWT" };
  const iat = Math.floor(now / 1e3);
  const claims = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: iat + 3600,
    iat
  };
  const unsigned = `${base64UrlFromString(JSON.stringify(header))}.${base64UrlFromString(JSON.stringify(claims))}`;
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(unsigned)
  );
  const jwt = `${unsigned}.${base64UrlFromBytes(new Uint8Array(signature))}`;
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt
    })
  });
  const data = await res.json();
  if (!res.ok || !data.access_token) {
    throw new Error(`Google token exchange failed: ${res.status} ${JSON.stringify(data)}`);
  }
  _fcmTokenCache = {
    accessToken: data.access_token,
    expiresAt: now + (data.expires_in || 3600) * 1e3
  };
  return data.access_token;
}
__name(getFirebaseAccessToken, "getFirebaseAccessToken");
async function sendFcmMessage(env, { token, topic, title, body, clickUrl }) {
  if (!env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    return { ok: false, reason: "FIREBASE_SERVICE_ACCOUNT_JSON not configured" };
  }
  const sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON);
  const accessToken = await getFirebaseAccessToken(env);
  const message = {
    notification: { title, body },
    ...clickUrl ? { data: { click_action: clickUrl, url: clickUrl } } : {},
    ...token ? { token } : { topic }
  };
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "content-type": "application/json"
      },
      body: JSON.stringify({ message })
    }
  );
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    return { ok: false, status: res.status, body: data };
  }
  return { ok: true, name: data.name };
}
__name(sendFcmMessage, "sendFcmMessage");
async function handlePushSend(request, env) {
  const secret = request.headers.get("x-brikstax-push-secret");
  if (!env.PUSH_SEND_SECRET || secret !== env.PUSH_SEND_SECRET) {
    return err("Unauthorized", 401);
  }
  let body;
  try {
    body = await request.json();
  } catch {
    return err("Invalid JSON");
  }
  const { title, body: messageBody, token, topic, url } = body;
  if (!title || !messageBody) return err("Missing title or body");
  if (!token && !topic) return err("Missing token or topic");
  try {
    const result = await sendFcmMessage(env, {
      token,
      topic,
      title,
      body: messageBody,
      clickUrl: url
    });
    return json(result, result.ok ? 200 : 502);
  } catch (e) {
    return err("Send failed: " + e.message, 500);
  }
}
__name(handlePushSend, "handlePushSend");
async function handleCommunityClaimRewards(request, env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  let body;
  try {
    body = await request.json();
  } catch {
    return err("Invalid JSON");
  }
  const userId = body.user_id;
  if (!userId) return err("Missing user_id");
  try {
    const totalRow = await env.PRICE_CACHE.prepare(`
      SELECT COUNT(*) as cnt FROM community_likes cl
      JOIN community_posts cp ON cl.post_id = cp.id
      WHERE cp.user_id = ?
    `).bind(userId).first();
    const totalLikes = totalRow?.cnt || 0;
    const stateRow = await env.PRICE_CACHE.prepare(
      "SELECT claimed_likes FROM community_reward_state WHERE user_id = ?"
    ).bind(userId).first();
    const claimedLikes = stateRow?.claimed_likes || 0;
    const unclaimed = Math.max(0, totalLikes - claimedLikes);
    const briksEarned = unclaimed * BRIKS_PER_LIKE;
    if (unclaimed > 0) {
      await env.PRICE_CACHE.prepare(`
        INSERT INTO community_reward_state (user_id, claimed_likes)
        VALUES (?, ?)
        ON CONFLICT(user_id) DO UPDATE SET claimed_likes = excluded.claimed_likes
      `).bind(userId, totalLikes).run();
    }
    return json({ briksEarned, totalLikes });
  } catch (e) {
    return err("DB error: " + e.message, 500);
  }
}
__name(handleCommunityClaimRewards, "handleCommunityClaimRewards");
async function handleCommunityModerate(request, env) {
  if (!env.PRICE_CACHE) return err("No D1 binding");
  const secret = request.headers.get("x-brikstax-secret");
  if (secret !== (env.NEWS_SECRET || "brikstax2026")) return err("Unauthorized", 401);
  let body;
  try {
    body = await request.json();
  } catch {
    return err("Invalid JSON");
  }
  const { id, action, reviewer } = body;
  if (!id || !["approve", "reject"].includes(action)) {
    return err("Missing id or invalid action (must be approve|reject)");
  }
  const post = await env.PRICE_CACHE.prepare(
    "SELECT * FROM community_posts WHERE id = ?"
  ).bind(id).first();
  if (!post) return err("Post not found", 404);
  if (post.status !== "pending") {
    return err(`Post already ${post.status}`, 409);
  }
  const newStatus = action === "approve" ? "approved" : "rejected";
  let newKey = post.image_key;
  if (action === "approve" && env.COMMUNITY_PHOTOS) {
    newKey = post.image_key.replace(/^pending\//, "approved/");
    try {
      const obj = await env.COMMUNITY_PHOTOS.get(post.image_key);
      if (obj) {
        await env.COMMUNITY_PHOTOS.put(newKey, obj.body, {
          httpMetadata: obj.httpMetadata
        });
        await env.COMMUNITY_PHOTOS.delete(post.image_key);
      }
    } catch (e) {
      console.error("R2 move failed:", e.message);
      newKey = post.image_key;
    }
  }
  try {
    await env.PRICE_CACHE.prepare(`
      UPDATE community_posts
      SET status = ?, reviewed_at = ?, reviewed_by = ?, image_key = ?
      WHERE id = ?
    `).bind(newStatus, Date.now(), reviewer || "discord", newKey, id).run();
  } catch (e) {
    return err("DB error: " + e.message, 500);
  }
  if (action === "reject" && env.COMMUNITY_PHOTOS) {
    await env.COMMUNITY_PHOTOS.delete(post.image_key).catch(() => {
    });
  }
  return json({ ok: true, id, status: newStatus });
}
__name(handleCommunityModerate, "handleCommunityModerate");
async function handleDiscordModerate(options, env, action) {
  const id = opt(options, "id");
  if (!id) return discordReply("\u274C Missing post id.");
  const post = await env.PRICE_CACHE.prepare(
    "SELECT * FROM community_posts WHERE id = ?"
  ).bind(id).first();
  if (!post) return discordReply(`\u274C No post found with id ${id}.`);
  if (post.status !== "pending") return discordReply(`\u26A0\uFE0F Post #${id} is already **${post.status}**.`);
  const newStatus = action === "approve" ? "approved" : "rejected";
  let newKey = post.image_key;
  if (action === "approve" && env.COMMUNITY_PHOTOS) {
    newKey = post.image_key.replace(/^pending\//, "approved/");
    try {
      const obj = await env.COMMUNITY_PHOTOS.get(post.image_key);
      if (obj) {
        await env.COMMUNITY_PHOTOS.put(newKey, obj.body, { httpMetadata: obj.httpMetadata });
        await env.COMMUNITY_PHOTOS.delete(post.image_key);
      }
    } catch (e) {
      newKey = post.image_key;
    }
  }
  try {
    await env.PRICE_CACHE.prepare(`
      UPDATE community_posts SET status = ?, reviewed_at = ?, reviewed_by = ?, image_key = ?
      WHERE id = ?
    `).bind(newStatus, Date.now(), "discord", newKey, id).run();
  } catch (e) {
    return discordReply(`\u274C DB error: ${e.message}`);
  }
  if (action === "reject" && env.COMMUNITY_PHOTOS) {
    await env.COMMUNITY_PHOTOS.delete(post.image_key).catch(() => {
    });
  }
  return discordReply(
    action === "approve" ? `\u2705 Post #${id} approved and is now live in the feed.` : `\u{1F5D1}\uFE0F Post #${id} rejected and deleted.`
  );
}
__name(handleDiscordModerate, "handleDiscordModerate");
async function handleDiscordTrust(options, env, trust) {
  const userId = opt(options, "user_id");
  if (!userId) return discordReply("\u274C Missing user_id.");
  try {
    if (trust) {
      await env.PRICE_CACHE.prepare(`
        INSERT INTO trusted_users (user_id, trusted_by, trusted_at)
        VALUES (?, ?, ?)
        ON CONFLICT(user_id) DO UPDATE SET
          trusted_by = excluded.trusted_by, trusted_at = excluded.trusted_at
      `).bind(userId, "discord", Date.now()).run();
      return discordReply(`\u2705 **${userId}** is now trusted \u2014 2 hour cooldown instead of 6.`);
    } else {
      const result = await env.PRICE_CACHE.prepare(
        "DELETE FROM trusted_users WHERE user_id = ?"
      ).bind(userId).run();
      if ((result.meta?.changes ?? 0) === 0) {
        return discordReply(`\u26A0\uFE0F **${userId}** wasn't trusted to begin with.`);
      }
      return discordReply(`\u2705 **${userId}** is no longer trusted \u2014 back to the standard 6 hour cooldown.`);
    }
  } catch (e) {
    return discordReply(`\u274C DB error: ${e.message}`);
  }
}
__name(handleDiscordTrust, "handleDiscordTrust");
async function handleDiscordDelete(options, env) {
  const type = opt(options, "type");
  const id = opt(options, "id");
  if (!type || id == null) return discordReply("\u274C Missing type or id.");
  if (type === "news") {
    try {
      const row = await env.PRICE_CACHE.prepare(
        "SELECT title, type FROM news WHERE id = ?"
      ).bind(id).first();
      if (!row) return discordReply(`\u274C No news/update post found with id #${id}.`);
      await env.PRICE_CACHE.prepare("DELETE FROM news WHERE id = ?").bind(id).run();
      return discordReply(`\u{1F5D1}\uFE0F Deleted ${row.type} #${id}: **${row.title}**`);
    } catch (e) {
      return discordReply(`\u274C DB error: ${e.message}`);
    }
  }
  if (type === "deal") {
    try {
      const row = await env.PRICE_CACHE.prepare(
        "SELECT title, retailer FROM deals WHERE id = ?"
      ).bind(id).first();
      if (!row) return discordReply(`\u274C No deal found with id #${id}.`);
      await env.PRICE_CACHE.prepare("DELETE FROM deals WHERE id = ?").bind(id).run();
      return discordReply(`\u{1F5D1}\uFE0F Deleted deal #${id}: **${row.title}**${row.retailer ? ` (${row.retailer})` : ""}`);
    } catch (e) {
      return discordReply(`\u274C DB error: ${e.message}`);
    }
  }
  if (type === "community") {
    try {
      const row = await env.PRICE_CACHE.prepare(
        "SELECT image_key, status, caption FROM community_posts WHERE id = ?"
      ).bind(id).first();
      if (!row) return discordReply(`\u274C No community post found with id #${id}.`);
      if (env.COMMUNITY_PHOTOS && row.image_key) {
        await env.COMMUNITY_PHOTOS.delete(row.image_key).catch(() => {
        });
      }
      await env.PRICE_CACHE.prepare("DELETE FROM community_posts WHERE id = ?").bind(id).run();
      return discordReply(`\u{1F5D1}\uFE0F Deleted community post #${id} (was **${row.status}**)${row.caption ? ` \u2014 "${row.caption}"` : ""}`);
    } catch (e) {
      return discordReply(`\u274C DB error: ${e.message}`);
    }
  }
  return discordReply(`\u274C Unknown type "${type}" \u2014 must be news, deal, or community.`);
}
__name(handleDiscordDelete, "handleDiscordDelete");
async function handleDiscordRecent(options, env) {
  const type = opt(options, "type");
  const limit = Math.min(opt(options, "limit") || 10, 25);
  if (!type) return discordReply("\u274C Missing type.");
  try {
    if (type === "news") {
      const rows = await env.PRICE_CACHE.prepare(
        "SELECT id, title, type FROM news ORDER BY posted_at DESC LIMIT ?"
      ).bind(limit).all();
      const items = rows.results || [];
      if (!items.length) return discordReply("No news/update posts yet.");
      const lines = items.map((r) => `#${r.id} [${r.type}] ${r.title}`);
      return discordReply(`**Recent news/updates:**
${lines.join("\n")}`);
    }
    if (type === "deal") {
      const rows = await env.PRICE_CACHE.prepare(
        "SELECT id, title, retailer, expires_at FROM deals ORDER BY created_at DESC LIMIT ?"
      ).bind(limit).all();
      const items = rows.results || [];
      if (!items.length) return discordReply("No deals yet.");
      const now = Date.now();
      const lines = items.map((r) => {
        const expired = r.expires_at && r.expires_at < now ? " (expired)" : "";
        return `#${r.id} [${r.retailer || "\u2014"}] ${r.title}${expired}`;
      });
      return discordReply(`**Recent deals:**
${lines.join("\n")}`);
    }
    if (type === "community") {
      const rows = await env.PRICE_CACHE.prepare(
        "SELECT id, status, caption, set_num FROM community_posts ORDER BY submitted_at DESC LIMIT ?"
      ).bind(limit).all();
      const items = rows.results || [];
      if (!items.length) return discordReply("No community posts yet.");
      const lines = items.map((r) => `#${r.id} [${r.status}]${r.set_num ? ` (${r.set_num})` : ""} ${r.caption || "(no caption)"}`);
      return discordReply(`**Recent community posts:**
${lines.join("\n")}`);
    }
    return discordReply(`\u274C Unknown type "${type}" \u2014 must be news, deal, or community.`);
  } catch (e) {
    return discordReply(`\u274C DB error: ${e.message}`);
  }
}
__name(handleDiscordRecent, "handleDiscordRecent");
async function cleanupExpiredCommunityPosts(env) {
  if (!env.PRICE_CACHE) {
    console.error("No D1 binding for cleanup");
    return;
  }
  const cutoff = Date.now() - COMMUNITY_POST_LIFETIME_MS;
  try {
    const expired = await env.PRICE_CACHE.prepare(`
      SELECT id, image_key FROM community_posts
      WHERE status = 'approved' AND reviewed_at IS NOT NULL AND reviewed_at < ?
    `).bind(cutoff).all();
    const rows = expired.results || [];
    if (rows.length === 0) {
      console.log("Community cleanup: nothing expired");
      return;
    }
    let deleted = 0;
    for (const row of rows) {
      try {
        if (env.COMMUNITY_PHOTOS) {
          await env.COMMUNITY_PHOTOS.delete(row.image_key);
        }
        await env.PRICE_CACHE.prepare(
          "DELETE FROM community_posts WHERE id = ?"
        ).bind(row.id).run();
        deleted++;
      } catch (e) {
        console.error(`Community cleanup failed for post ${row.id}:`, e.message);
      }
    }
    console.log(`Community cleanup: deleted ${deleted}/${rows.length} expired posts`);
  } catch (e) {
    console.error("Community cleanup query failed:", e.message);
  }
}
__name(cleanupExpiredCommunityPosts, "cleanupExpiredCommunityPosts");
async function handleNewsLinkDeferred(linkUrl, interactionBody, env) {
  const applicationId = interactionBody.application_id;
  const interactionToken = interactionBody.token;
  const followupUrl = `https://discord.com/api/v10/webhooks/${applicationId}/${interactionToken}/messages/@original`;
  async function editReply(content) {
    try {
      await fetch(followupUrl, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ content })
      });
    } catch (e) {
      console.error("Failed to edit deferred reply:", e.message);
    }
  }
  __name(editReply, "editReply");
  let html;
  try {
    const res = await fetch(linkUrl, {
      headers: { "User-Agent": "BrikStax/2.4 (link preview bot)" }
    });
    if (!res.ok) {
      await editReply(`\u274C Couldn't fetch that link (HTTP ${res.status}).`);
      return;
    }
    html = await res.text();
  } catch (e) {
    await editReply(`\u274C Fetch failed: ${e.message}`);
    return;
  }
  function metaTag(prop) {
    const re1 = new RegExp(
      `<meta[^>]+property=["']${prop}["'][^>]+content=["']([^"']*)["']`,
      "i"
    );
    const re2 = new RegExp(
      `<meta[^>]+content=["']([^"']*)["'][^>]+property=["']${prop}["']`,
      "i"
    );
    const m = html.match(re1) || html.match(re2);
    return m ? decodeHtmlEntities(m[1]) : null;
  }
  __name(metaTag, "metaTag");
  function decodeHtmlEntities(str) {
    return str.replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&#0?39;/g, "'");
  }
  __name(decodeHtmlEntities, "decodeHtmlEntities");
  let title = metaTag("og:title");
  let summary = metaTag("og:description");
  let image = metaTag("og:image");
  if (!title) {
    const titleMatch = html.match(/<title[^>]*>([^<]*)<\/title>/i);
    title = titleMatch ? decodeHtmlEntities(titleMatch[1]).trim() : null;
  }
  if (!title) {
    await editReply(
      `\u26A0\uFE0F Couldn't find a title for that page. Try \`/news\` instead and enter it manually.`
    );
    return;
  }
  if (summary && summary.length > 280) {
    summary = summary.slice(0, 277) + "...";
  }
  try {
    await env.PRICE_CACHE.prepare(`
      INSERT INTO news (title, summary, url, image_url, posted_at, source, type)
      VALUES (?, ?, ?, ?, ?, 'discord', 'news')
    `).bind(title, summary || null, linkUrl, image || null, Date.now()).run();
    await editReply(`\u2705 News posted: **${title}**`);
  } catch (e) {
    await editReply(`\u274C DB error: ${e.message}`);
  }
}
__name(handleNewsLinkDeferred, "handleNewsLinkDeferred");
async function handleDealLinkDeferred(linkUrl, options, interactionBody, env) {
  const applicationId = interactionBody.application_id;
  const interactionToken = interactionBody.token;
  const followupUrl = `https://discord.com/api/v10/webhooks/${applicationId}/${interactionToken}/messages/@original`;
  async function editReply(content) {
    try {
      await fetch(followupUrl, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ content })
      });
    } catch (e) {
      console.error("Failed to edit deferred reply:", e.message);
    }
  }
  __name(editReply, "editReply");
  const price = opt(options, "price");
  const retail = opt(options, "retail");
  const setNum = opt(options, "set");
  const retailer = opt(options, "retailer");
  const note = opt(options, "note");
  const featured = opt(options, "featured");
  const days = opt(options, "days");
  let html;
  try {
    const res = await fetch(linkUrl, {
      headers: { "User-Agent": "BrikStax/2.4 (link preview bot)" }
    });
    if (!res.ok) {
      await editReply(`\u274C Couldn't fetch that link (HTTP ${res.status}).`);
      return;
    }
    html = await res.text();
  } catch (e) {
    await editReply(`\u274C Fetch failed: ${e.message}`);
    return;
  }
  function metaTag(prop) {
    const re1 = new RegExp(
      `<meta[^>]+property=["']${prop}["'][^>]+content=["']([^"']*)["']`,
      "i"
    );
    const re2 = new RegExp(
      `<meta[^>]+content=["']([^"']*)["'][^>]+property=["']${prop}["']`,
      "i"
    );
    const m = html.match(re1) || html.match(re2);
    return m ? decodeHtmlEntities(m[1]) : null;
  }
  __name(metaTag, "metaTag");
  function decodeHtmlEntities(str) {
    return str.replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&#0?39;/g, "'");
  }
  __name(decodeHtmlEntities, "decodeHtmlEntities");
  let title = metaTag("og:title");
  const image = metaTag("og:image");
  if (!title) {
    const titleMatch = html.match(/<title[^>]*>([^<]*)<\/title>/i);
    title = titleMatch ? decodeHtmlEntities(titleMatch[1]).trim() : null;
  }
  if (!title) {
    await editReply(
      `\u26A0\uFE0F Couldn't find a title for that page. Try \`/deal\` instead and enter it manually.`
    );
    return;
  }
  const expiresDays = days != null ? days : 30;
  const expires_at = Date.now() + expiresDays * 24 * 60 * 60 * 1e3;
  try {
    await env.PRICE_CACHE.prepare(`
      INSERT INTO deals
        (deal_id, title, set_num, retail_price, deal_price,
         retailer, url, image_url, note, featured, expires_at, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      null,
      title,
      setNum || null,
      retail != null ? retail : null,
      price,
      retailer || null,
      linkUrl,
      image || null,
      note || null,
      featured ? 1 : 0,
      expires_at,
      Date.now()
    ).run();
    const pct = retail && price ? ` (${Math.round((1 - price / retail) * 100)}% off)` : "";
    await editReply(`\u2705 Deal posted: **${title}**${pct}${featured ? " \u2B50 featured" : ""}`);
  } catch (e) {
    await editReply(`\u274C DB error: ${e.message}`);
  }
}
__name(handleDealLinkDeferred, "handleDealLinkDeferred");
var RSS_FEED_SOURCES = [
  { url: "https://brickset.com/feed", label: "Brickset" },
  { url: "https://www.jaysbrickblog.com/feed/", label: "Jay's Brick Blog" },
  { url: "http://feeds.feedburner.com/LegoEverlasting-LegoReviewsNews", label: "The Brick Fan" }
];
var RSS_NOISE_PATTERNS = [
  /^random (set|figure) of the day/i,
  /^this week's top news articles/i,
  /^what's hot this week/i,
  /^recent reviews$/i,
  /^vintage set of the week/i
];
function isRssNoise(title) {
  return RSS_NOISE_PATTERNS.some((re) => re.test(title.trim()));
}
__name(isRssNoise, "isRssNoise");
function extractSetNumber(title) {
  const m = title.match(/\b(\d{4,6})\b/);
  return m ? m[1] : null;
}
__name(extractSetNumber, "extractSetNumber");
function parseRssItems(xml) {
  const items = [];
  const itemBlocks = xml.split("<item>").slice(1);
  for (const block of itemBlocks) {
    const get = /* @__PURE__ */ __name((tag) => {
      const m = block.match(new RegExp(`<${tag}>([\\s\\S]*?)</${tag}>`));
      return m ? m[1].trim() : null;
    }, "get");
    const title = get("title");
    const link = get("link");
    const guid = get("guid");
    const pubDateRaw = get("pubDate");
    let description = get("description");
    if (!title || !link) continue;
    let image = null;
    if (description) {
      const imgMatch = description.match(/src=['"]([^'"]+)['"]/);
      if (imgMatch) image = imgMatch[1];
      description = description.replace(/<img[^>]*>/gi, "").replace(/<[^>]+>/g, " ").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&").replace(/&quot;/g, '"').replace(/&#0?39;/g, "'").replace(/\s+/g, " ").trim();
      if (description.length > 280) description = description.slice(0, 277) + "...";
    }
    items.push({
      title,
      url: link,
      guid: guid || link,
      summary: description,
      image,
      pubDate: pubDateRaw ? Date.parse(pubDateRaw) : Date.now()
    });
  }
  return items;
}
__name(parseRssItems, "parseRssItems");
async function shortHash(str) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(str));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("").slice(0, 16);
}
__name(shortHash, "shortHash");
async function ensureGuidHashColumns(env) {
  try {
    await env.PRICE_CACHE.prepare("ALTER TABLE rss_seen ADD COLUMN guid_hash TEXT").run();
  } catch (_) {
  }
  try {
    await env.PRICE_CACHE.prepare("ALTER TABLE deal_seen ADD COLUMN guid_hash TEXT").run();
  } catch (_) {
  }
}
__name(ensureGuidHashColumns, "ensureGuidHashColumns");
async function checkRssForNewsCandidates(env) {
  if (!env.PRICE_CACHE) {
    console.error("No D1 binding for RSS check");
    return;
  }
  if (!env.DISCORD_BOT_TOKEN) {
    console.error("No DISCORD_BOT_TOKEN for RSS candidates");
    return;
  }
  await ensureGuidHashColumns(env);
  const MOD_CHANNEL_ID = "1518832709378510878";
  const fetches = await Promise.all(RSS_FEED_SOURCES.map(async (feed) => {
    try {
      const res = await fetch(feed.url, {
        headers: { "User-Agent": "BrikStax/2.4 (RSS reader)" }
      });
      if (!res.ok) {
        console.error(`RSS fetch failed for ${feed.label}:`, res.status);
        return [];
      }
      const xml = await res.text();
      return parseRssItems(xml).map((item) => ({ ...item, source: feed.label }));
    } catch (e) {
      console.error(`RSS fetch error for ${feed.label}:`, e.message);
      return [];
    }
  }));
  const allItems = fetches.flat().filter((item) => !isRssNoise(item.title)).sort((a, b) => b.pubDate - a.pubDate);
  const candidates = [];
  const seenSetNumsThisRun = /* @__PURE__ */ new Set();
  for (const item of allItems) {
    if (candidates.length >= 10) break;
    const setNum = extractSetNumber(item.title);
    if (setNum && seenSetNumsThisRun.has(setNum)) continue;
    try {
      const seen = await env.PRICE_CACHE.prepare(
        "SELECT guid FROM rss_seen WHERE guid = ?"
      ).bind(item.guid).first();
      if (seen) continue;
    } catch (e) {
      console.error("rss_seen check failed:", e.message);
    }
    candidates.push(item);
    if (setNum) seenSetNumsThisRun.add(setNum);
  }
  if (candidates.length === 0) {
    console.log("RSS check: no new candidates");
    return;
  }
  for (const item of candidates) {
    item.hash = await shortHash(item.guid);
    try {
      await env.PRICE_CACHE.prepare(`
        INSERT INTO rss_seen (guid, title, url, image_url, summary, suggested_at, guid_hash)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(guid) DO NOTHING
      `).bind(item.guid, item.title, item.url, item.image, item.summary, Date.now(), item.hash).run();
    } catch (e) {
      console.error("rss_seen insert failed:", e.message);
    }
  }
  const lines = candidates.map(
    (item, i) => `**${i + 1}.** [${item.source}] ${item.title}
${item.url}`
  ).join("\n\n");
  const components = [];
  for (let i = 0; i < candidates.length; i += 5) {
    components.push({
      type: 1,
      components: candidates.slice(i, i + 5).map((item, j) => ({
        type: 2,
        style: 3,
        label: `Post #${i + j + 1}`,
        custom_id: `rss_post:${item.hash}`
      }))
    });
  }
  try {
    const res = await fetch(
      `https://discord.com/api/v10/channels/${MOD_CHANNEL_ID}/messages`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bot ${env.DISCORD_BOT_TOKEN}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          content: `\u{1F4F0} <@285276700562948106> **New LEGO articles found** \u2014 tap a button to post it to the news feed:

${lines}`,
          components,
          allowed_mentions: { users: ["285276700562948106"] }
        })
      }
    );
    const bodyText = await res.text().catch(() => "(no body)");
    console.log(`RSS candidates post response: ${res.status} \u2014 ${bodyText}`);
  } catch (e) {
    console.error("Failed to post RSS candidates to Discord:", e.message);
  }
}
__name(checkRssForNewsCandidates, "checkRssForNewsCandidates");
async function handleRssPostButton(customId, env) {
  const hash = customId.replace("rss_post:", "");
  try {
    const item = await env.PRICE_CACHE.prepare(
      "SELECT * FROM rss_seen WHERE guid_hash = ?"
    ).bind(hash).first();
    if (!item) {
      return discordReply("\u274C Couldn't find that article \u2014 it may have expired.");
    }
    await env.PRICE_CACHE.prepare(`
      INSERT INTO news (title, summary, url, image_url, posted_at, source, type)
      VALUES (?, ?, ?, ?, ?, 'discord', 'news')
    `).bind(item.title, item.summary, item.url, item.image_url, Date.now()).run();
    return discordReply(`\u2705 Posted: **${item.title}**`);
  } catch (e) {
    return discordReply(`\u274C DB error: ${e.message}`);
  }
}
__name(handleRssPostButton, "handleRssPostButton");
var SLICKDEALS_LEGO_RSS = "https://slickdeals.net/newsearch.php?rss=1&q=lego";
function extractPriceGuess(text) {
  if (!text) return null;
  const m = text.match(/\$?\s?(\d{1,4}(?:,\d{3})*\.\d{2})/);
  if (!m) return null;
  const v = parseFloat(m[1].replace(/,/g, ""));
  return isNaN(v) ? null : v;
}
__name(extractPriceGuess, "extractPriceGuess");
function inferRetailer(url) {
  try {
    const host = new URL(url).hostname.toLowerCase();
    if (host.includes("amazon.")) return "Amazon";
    if (host.includes("ebay.")) return "eBay";
    if (host.includes("walmart.")) return "Walmart";
    if (host.includes("target.")) return "Target";
    if (host.includes("lego.com")) return "LEGO";
    return null;
  } catch (_) {
    return null;
  }
}
__name(inferRetailer, "inferRetailer");
async function checkSlickdealsForDealCandidates(env) {
  const diag = { ok: true };
  if (!env.PRICE_CACHE) {
    diag.ok = false;
    diag.error = "no_db";
    return diag;
  }
  if (!env.DISCORD_BOT_TOKEN) {
    diag.ok = false;
    diag.error = "no_discord_bot_token";
    return diag;
  }
  await ensureGuidHashColumns(env);
  const MOD_CHANNEL_ID = "1518832709378510878";
  let xml;
  try {
    const res = await fetch(SLICKDEALS_LEGO_RSS, {
      headers: { "User-Agent": "BrikStax/2.4 (deal reader)" }
    });
    diag.slickdeals_status = res.status;
    if (!res.ok) {
      diag.ok = false;
      diag.error = `slickdeals_http_${res.status}`;
      return diag;
    }
    xml = await res.text();
    diag.xml_length = xml.length;
  } catch (e) {
    diag.ok = false;
    diag.error = `slickdeals_fetch_failed: ${e.message}`;
    return diag;
  }
  const rawItems = parseRssItems(xml);
  diag.rss_items_parsed = rawItems.length;
  const items = rawItems.filter((item) => /lego/i.test(item.title)).sort((a, b) => b.pubDate - a.pubDate);
  diag.items_matching_lego = items.length;
  diag.sample_titles = rawItems.slice(0, 5).map((i) => i.title);
  const candidates = [];
  let alreadySeenCount = 0;
  for (const item of items) {
    if (candidates.length >= 8) break;
    try {
      const seen = await env.PRICE_CACHE.prepare(
        "SELECT guid FROM deal_seen WHERE guid = ?"
      ).bind(item.guid).first();
      if (seen) {
        alreadySeenCount++;
        continue;
      }
    } catch (e) {
      diag.deal_seen_check_error = e.message;
    }
    candidates.push(item);
  }
  diag.already_seen = alreadySeenCount;
  diag.new_candidates = candidates.length;
  if (candidates.length === 0) {
    diag.posted = false;
    return diag;
  }
  const priceGuesses = /* @__PURE__ */ new Map();
  for (const item of candidates) {
    const guess = extractPriceGuess(item.title) ?? extractPriceGuess(item.summary);
    priceGuesses.set(item.guid, guess);
    item.hash = await shortHash(item.guid);
    try {
      await env.PRICE_CACHE.prepare(`
        INSERT INTO deal_seen (guid, title, url, image_url, summary, price_guess, suggested_at, guid_hash)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(guid) DO NOTHING
      `).bind(item.guid, item.title, item.url, item.image, item.summary, guess, Date.now(), item.hash).run();
    } catch (e) {
      diag.deal_seen_insert_error = e.message;
    }
  }
  const lines = candidates.map((item, i) => {
    const guess = priceGuesses.get(item.guid);
    return `**${i + 1}.** ${item.title}${guess != null ? ` \u2014 ~$${guess.toFixed(2)}` : ""}
${item.url}`;
  }).join("\n\n");
  const components = [];
  for (let i = 0; i < candidates.length; i += 5) {
    components.push({
      type: 1,
      components: candidates.slice(i, i + 5).map((item, j) => ({
        type: 2,
        style: 3,
        label: `Post #${i + j + 1}`,
        custom_id: `deal_post:${item.hash}`
      }))
    });
  }
  try {
    const res = await fetch(
      `https://discord.com/api/v10/channels/${MOD_CHANNEL_ID}/messages`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bot ${env.DISCORD_BOT_TOKEN}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          content: `\u{1F4B8} <@285276700562948106> **New LEGO deals found** \u2014 tap a button, confirm the price, and it posts to the deals feed. Open the deal page first if you want the affiliate link applied \u2014 the modal's retailer-link field needs the real Amazon/eBay URL, not this Slickdeals link:

${lines}`,
          components,
          allowed_mentions: { users: ["285276700562948106"] }
        })
      }
    );
    const bodyText = await res.text().catch(() => "(no body)");
    diag.posted = res.ok;
    diag.discord_status = res.status;
    diag.discord_body = bodyText;
  } catch (e) {
    diag.posted = false;
    diag.discord_post_error = e.message;
  }
  return diag;
}
__name(checkSlickdealsForDealCandidates, "checkSlickdealsForDealCandidates");
async function handleDealPostButton(customId, env) {
  const hash = customId.replace("deal_post:", "");
  const cached = await env.PRICE_CACHE.prepare(
    "SELECT * FROM deal_seen WHERE guid_hash = ?"
  ).bind(hash).first();
  if (!cached) return discordReply("\u274C Couldn't find that deal \u2014 it may have expired.");
  const modalTitle = cached.title.length > 40 ? cached.title.slice(0, 37) + "..." : cached.title;
  return new Response(JSON.stringify({
    type: DISCORD_MODAL,
    data: {
      custom_id: `deal_modal:${hash}`,
      title: modalTitle,
      components: [
        {
          type: 1,
          components: [{
            type: 4,
            // TEXT_INPUT
            style: 1,
            // short
            custom_id: "price",
            label: "Deal price",
            placeholder: "e.g. 39.99",
            value: cached.price_guess != null ? String(cached.price_guess) : void 0,
            required: true
          }]
        },
        {
          type: 1,
          components: [{
            type: 4,
            style: 1,
            custom_id: "retail",
            label: "Retail / MSRP price (optional)",
            placeholder: "e.g. 49.99",
            required: false
          }]
        },
        {
          type: 1,
          components: [{
            type: 4,
            style: 1,
            custom_id: "url",
            // Slickdeals' own <link> always points to their slickdeals.net/f/...
            // deal page, never straight to the retailer -- open that page, find
            // the actual "Buy Now" / outbound link, paste it here. Left blank,
            // this posts the Slickdeals page itself and gets no affiliate tag,
            // since inferRetailer() can't identify Amazon/eBay from a
            // slickdeals.net URL.
            label: "Direct retailer link (for affiliate tag)",
            placeholder: "Amazon/eBay link from the deal page -- blank = no affiliate tag",
            required: false
          }]
        }
      ]
    }
  }), { headers: { "Content-Type": "application/json" } });
}
__name(handleDealPostButton, "handleDealPostButton");
async function handleDealModalSubmit(customId, interactionBody, env) {
  const hash = customId.replace("deal_modal:", "");
  const values = {};
  for (const row of interactionBody.data.components || []) {
    for (const comp of row.components || []) {
      values[comp.custom_id] = comp.value;
    }
  }
  const price = parseFloat(values.price);
  const retail = values.retail ? parseFloat(values.retail) : null;
  if (!values.price || isNaN(price)) {
    return discordReply("\u274C Invalid price -- try the button again.");
  }
  const cached = await env.PRICE_CACHE.prepare(
    "SELECT * FROM deal_seen WHERE guid_hash = ?"
  ).bind(hash).first();
  if (!cached) return discordReply("\u274C Couldn't find that deal \u2014 it may have expired.");
  const rawUrl = values.url && values.url.trim() || cached.url;
  const retailer = inferRetailer(rawUrl);
  let url = rawUrl;
  try {
    if (retailer === "Amazon") url = buildAmazonAffiliateLink(url);
    else if (retailer === "eBay") url = buildEbayAffiliateLink(url);
  } catch (_) {
  }
  const expires_at = Date.now() + 30 * 24 * 60 * 60 * 1e3;
  try {
    await env.PRICE_CACHE.prepare(`
      INSERT INTO deals
        (deal_id, title, set_num, retail_price, deal_price,
         retailer, url, image_url, note, featured, expires_at, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      null,
      cached.title,
      null,
      retail,
      price,
      retailer,
      url,
      cached.image_url,
      null,
      0,
      expires_at,
      Date.now()
    ).run();
    const pct = retail && price ? ` (${Math.round((1 - price / retail) * 100)}% off)` : "";
    const tagNote = retailer === "Amazon" || retailer === "eBay" ? ` \u2014 affiliate link applied` : ` \u2014 \u26A0\uFE0F no affiliate link (no retailer URL given)`;
    return discordReply(`\u2705 Deal posted${retailer ? ` (${retailer})` : ""}: **${cached.title}** \u2014 $${price.toFixed(2)}${pct}${tagNote}`);
  } catch (e) {
    return discordReply(`\u274C DB error: ${e.message}`);
  }
}
__name(handleDealModalSubmit, "handleDealModalSubmit");
export {
  worker_default as default
};
//# sourceMappingURL=worker.js.map

