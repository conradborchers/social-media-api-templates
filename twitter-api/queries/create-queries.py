from itertools import product 

# User-defined input, try to use German words only
# Umlaute are automatically generalized by Twitter API, please use ae, oe, ue, ss
# Hyphens in hashtags are not allowed

pre_fach = [ "bio", "biologie", "chemie", "chinesisch", "deutsch", "englisch", 
"erdkunde", "erziehungswissenschaft", "ethik", "evangelisch", 
"franzoesisch", "gemeinschaftskunde", "geo", "geographie", "geologie", 
"geschichte", "geschichts", "griechisch", "hebraeisch", "informatik", 
"islamisch", "italienisch", "japanisch", "juedisch", "katholisch", 
"kunst", "latein", "lateinisch", "literatur", "mathe", "mathematik", 
"medienbildung", "musik", "neugriechisch", "niederlaendisch", 
"paeda", "paedagogik", "philo", "philosophie", "physik", "politik", 
"polnisch", "portugiesisch", "psychologie", "recht", "reli", 
"religion", "religions", "religionslehre", "russisch", "sowi", 
"sozialkunde", "sozialwissenschaften", "spanisch", "sport", "technik", 
"tschechisch", "tuerkisch", "wirtschaft", "wirtschafts"
]

suff_fach = [
"abi",
"abitur",
"bildung",
"chat",
"didaktik",
"digital",
"edchat",
"edu",
"ed",
"fachdidaktik",
"fortbildung",
"hauptfach",
"kernfach",
"lernen",
"lehren",
"lehrer",
"lehrerbildung",
"lehrerin",
"lehrerinnen",
"lehrerinnenbildung",
"lehrkraft",
"lehrkraftbildung",
"lehrkraefte",
"leitfach",
"pflichtfach",
"schule",
"schulfach",
"schulfachdidaktik",
"unterricht",
"weiterbildung",
"wettbewerb"
]

## FIXME: Später Einheitliches Reporting der Hashtags ohne Umlaute auch wenn
## von API beides erkannt!
pre_bund = ["badenwuerttemberg", "bawue", "bay", "bayern", "bb", "be", 
"ber", "berlin", "brandenburg", "bremen", "bw", "by", "hamburg", 
"hb", "he", "hessen", "hh", "mecklenburgvorpommern", "mv", "nds", 
"ni", "niedersachsen", "nordrheinwestphalen", "nrw", "nw", "rheinlandpfalz", 
"rlp", "rp", "sa", "saarland", "sachsen", "sachsen-anhalt", "schleswig-holstein", 
"sh", "sl", "sn", "th", "thueringen"
]

suff_bund = [
"bildung",
"bildungdigital",
"bildungsland",
"didaktik",
"digital",
"digitalebildung",
"digitaleschule",
"digitaleslernen",
"ed",
"edu",
"education",
"lehre",
"lehrer",
"lehrerinnen",
"lehrkraft",
"lehrkraefte",
"schulbehoerde",
"schulcloud",
"schule",
"schulen",
"schuledigital",
"schulentwicklung",
"unterricht"
#"homeschooling",
#"schulschliessung",
]

# Combinations, also add reversal
def combs(a, b): return(list(product(a, b)))

fach = ["".join(["#",a,b]) for a, b in combs(pre_fach, suff_fach)]
fach += ["".join(["#",b,a]) for a, b in combs(pre_fach, suff_fach)]
fach += ["".join(["#",a, "_", b]) for a, b in combs(pre_fach, suff_fach)]
fach += ["".join(["#",b, "_",a]) for a, b in combs(pre_fach, suff_fach)]

bundesland = ["".join(["#",a,b]) for a, b in combs(pre_bund, suff_bund)]
bundesland += ["".join(["#",b,a]) for a, b in combs(pre_bund, suff_bund)]
bundesland += ["".join(["#",a,"_",b]) for a, b in combs(pre_bund, suff_bund)]
bundesland += ["".join(["#",b,"_",a]) for a, b in combs(pre_bund, suff_bund)]

# Output
with open("queries.txt", "w") as f:
    for item in sorted(fach+bundesland):
        f.write("%s\n" %item)
