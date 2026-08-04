function longBracketAt(source, index) {
  if (source[index] !== "[") return null;
  let cursor = index + 1;
  while (source[cursor] === "=") cursor++;
  if (source[cursor] !== "[") return null;
  const equals = source.slice(index + 1, cursor);
  return {
    openLength: cursor - index + 1,
    close: `]${equals}]`,
  };
}

export function stripLuaComments(source) {
  let output = "";
  let index = 0;

  while (index < source.length) {
    const char = source[index];

    if (char === "\"" || char === "'") {
      const quote = char;
      output += char;
      index++;
      while (index < source.length) {
        const current = source[index];
        output += current;
        index++;
        if (current === "\\" && index < source.length) {
          output += source[index];
          index++;
        } else if (current === quote) {
          break;
        }
      }
      continue;
    }

    const longString = longBracketAt(source, index);
    if (longString) {
      const closeAt = source.indexOf(
        longString.close,
        index + longString.openLength,
      );
      const end = closeAt < 0
        ? source.length
        : closeAt + longString.close.length;
      output += source.slice(index, end);
      index = end;
      continue;
    }

    if (char === "-" && source[index + 1] === "-") {
      const block = longBracketAt(source, index + 2);
      output += " ";
      if (block) {
        const contentStart = index + 2 + block.openLength;
        const closeAt = source.indexOf(block.close, contentStart);
        const end = closeAt < 0
          ? source.length
          : closeAt + block.close.length;
        const comment = source.slice(index, end);
        output += comment.replace(/[^\r\n]/g, "");
        index = end;
      } else {
        index += 2;
        while (index < source.length && source[index] !== "\n") index++;
      }
      continue;
    }

    output += char;
    index++;
  }

  const lines = output
    .split(/\r?\n/)
    .map((line) => line.replace(/[ \t]+$/g, ""))
    .filter((line, lineIndex, lines) => (
      line.trim() !== "" || (lineIndex > 0 && lines[lineIndex - 1].trim() !== "")
    ));
  while (lines.length > 0 && lines[lines.length - 1].trim() === "") lines.pop();
  return lines.join("\n").trimStart() + "\n";
}
