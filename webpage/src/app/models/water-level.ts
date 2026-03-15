// Map to find volume from height of mm probe.
// Spreadsheet to calculate this from CAD, courtesy of Mark Kelly / DE1 app.
const waterMap: number[] = [
    0, 16, 43, 70, 97, 124, 151, 179, 206, 233, 261, 288, 316, 343, 371, 398, 426, 453, 481, 509, 537,
    564, 592, 620, 648, 676, 704, 732, 760, 788, 816, 844, 872, 900, 929, 957, 985, 1013, 1042, 1070,
    1104, 1138, 1172, 1207, 1242, 1277, 1312, 1347, 1382, 1417, 1453, 1488, 1523, 1559, 1594, 1630,
    1665, 1701, 1736, 1772, 1808, 1843, 1879, 1915, 1951, 1986, 2022, 2058,
];

export class WaterLevel {
    constructor(public waterLevel: number, public waterLimit: number) { }

    getLevelPercent(): number {
        const l = this.waterLevel - this.waterLimit;
        return Math.trunc((l * 100) / 8300);
    }

    getLevelMM(): number {
        const l = this.waterLevel;
        return Math.round(l / 256);
    }

    getLevelML(): number {
        const l = this.getLevelMM() + 5; // probe offset
        return l > 0 && l < waterMap.length ? waterMap[l] : 0;
    }

    getLevelRefill(): number {
        const l = Math.round(this.waterLimit / 256);
        return l > 0 && l < waterMap.length ? waterMap[l] : 0;
    }

    static getLevelFromHeight(height: number): number {
        const l = Math.round(height / 256);
        return l > 0 && l < waterMap.length ? waterMap[l] : 0;
    }

    static getLevelFromVolume(vol: number): number {
        for (let i = 0; i < waterMap.length; i++) {
            if (waterMap[i] > vol) return i - 1;
        }
        return 0;
    }
}