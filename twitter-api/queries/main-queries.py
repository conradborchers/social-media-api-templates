htags = [
"#edchatde",
"#lehrerzimmer",
"#tlz",
"#twitterkollegium",
"#twitterlehrerzimmer",
"#twitterlz",
"#twlz"
]

# Output
with open("queries.txt", "w") as f:
    for item in sorted(htags):
        f.write("%s\n" %item)
