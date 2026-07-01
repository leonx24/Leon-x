const fs = require('fs');
const path = require('path');

try {
    const filePath = path.join(__dirname, '..', 'modules', 'games', 'growagarden2.lua');
    const code = fs.readFileSync(filePath, 'utf8');
    
    let doCount = 0;
    let thenCount = 0;
    let functionCount = 0;
    let endCount = 0;
    let ifCount = 0;
    
    const words = code.match(/\b(do|then|function|end|if)\b/g) || [];
    words.forEach(w => {
        if (w === 'do') doCount++;
        else if (w === 'then') thenCount++;
        else if (w === 'function') functionCount++;
        else if (w === 'if') ifCount++;
        else if (w === 'end') endCount++;
    });
    
    console.log(`Frequencies: do=${doCount}, then=${thenCount}, function=${functionCount}, if=${ifCount}, end=${endCount}`);
    const expectedEnds = functionCount + ifCount + doCount;
    console.log(`Expected ends around: ${expectedEnds}, Actual ends: ${endCount}`);
} catch (e) {
    console.error(e);
}
