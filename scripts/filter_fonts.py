import sys
import glob


def sort_filter(filter):
    return "".join(sorted(set("".join(filter))))


def extract_word(line:str): 
    label = line.split('<')[1].split('>')[1]
    return "".join(label.split("\\n"))


def filter(filename:str, translatable:bool):
    with open(filename, 'r', encoding="utf-8") as f:
        lines = f.readlines()
        small_filter = [" .0123456789-:"]
        medium_filter = [" .0123456789-:'"]
        large_filter = [" .0123456789-"]
        current_filters = []
        for line in lines:
            if '$$$' in line:
                current_filters = []
                if 'Small' in line:
                    current_filters.append(small_filter)
                if 'Medium' in line:
                    current_filters.append(medium_filter)
                if 'Large' in line:
                    current_filters.append(large_filter)

            if 'string id' in line:
                if translatable != ('translatable="false"' in line):
                    word = extract_word(line)
                    for filter in current_filters:
                        filter += word

    return sort_filter(small_filter), sort_filter(medium_filter), sort_filter(large_filter)


def filter_all(rootpath):
    files = glob.glob('**/strings.xml', root_dir=rootpath, recursive=True)

    not_translatables = filter(files[0], False)
    global_filter = [f for f in not_translatables]
    for f in files:
        filters = filter(f, True)
        print(f, {
            "small":    sort_filter(filters[0]+not_translatables[0]),
            "medium":   sort_filter(filters[1]+not_translatables[1]),
            "large":    sort_filter(filters[2]+not_translatables[2])
        })
        for i in range(3):
            global_filter[i] = sort_filter(filters[i]+global_filter[i])
    print("global", {
        "small":    global_filter[0],
        "medium":   global_filter[1],
        "large":    global_filter[2]
    })


if __name__ == '__main__':
    filter_all(sys.argv[1])