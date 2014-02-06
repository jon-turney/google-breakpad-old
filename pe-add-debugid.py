#! /usr/bin/env python
#
# very hacky script to inject a build-id into a pe image
# pefile can't add a section, so we expect one to have been added beforehand using objcopy
# for simplicity, we just use a random build-id
#

import sys
import random
import pefile

random.seed()

file = sys.argv[1]
pe = pefile.PE(file)

if hasattr(pe, 'DIRECTORY_ENTRY_DEBUG'):
    print "%s already has a debug directory" % file
    sys.exit(1)

s = None
start_vma = 0
end_vma = 0

for i in pe.sections:
    if i.Name == '.buildid':
        s = i
        continue

    vma_size = (i.Misc_VirtualSize + pe.OPTIONAL_HEADER.SectionAlignment) & ~(pe.OPTIONAL_HEADER.SectionAlignment -1)
    section_end_vma = i.VirtualAddress + vma_size
    print "section %s vma start %x vma size %x vma end %x" % (i.Name, i.VirtualAddress, vma_size, section_end_vma)

    if section_end_vma > end_vma:
        end_vma = section_end_vma

if not s:
    print "%s has no .buildid section" % file
    print "Don't run this script directly, use py-add-debugid"
    sys.exit(1)

## XXX: sections must be in order and contiguous

# fix up the VMA for .buildid section and SizeOfImage
print "Fixing .buildid to vma %x" % end_vma
s.VirtualAddress = end_vma
print "Fixing SizeOfImage to %x" % (end_vma - start_vma)
pe.OPTIONAL_HEADER.SizeOfImage = end_vma - start_vma

offset = s.PointerToRawData

# set the data directory to point to a debug directory containing one entry
pe.OPTIONAL_HEADER.DATA_DIRECTORY[6].VirtualAddress = s.VirtualAddress
pe.OPTIONAL_HEADER.DATA_DIRECTORY[6].Size = 28

# write the debug directory entry
pe.set_dword_at_offset(offset, 0);
pe.set_dword_at_offset(offset + 4, 0);
pe.set_word_at_offset(offset + 8, 0);
pe.set_word_at_offset(offset + 10, 0);
pe.set_dword_at_offset(offset + 12, 2); # codeview debug info
pe.set_dword_at_offset(offset + 16, 25);  # size of pdb70 codeview record
pe.set_dword_at_offset(offset + 20, 0);
pe.set_dword_at_offset(offset + 24, s.PointerToRawData + 28);

# write the cv record
pe.set_dword_at_offset(offset + 28, 0x53445352); # "RSDS"
pe.set_dword_at_offset(offset + 32, random.getrandbits(32)); # 16-byte GUID
pe.set_dword_at_offset(offset + 36, random.getrandbits(32));
pe.set_dword_at_offset(offset + 40, random.getrandbits(32));
pe.set_dword_at_offset(offset + 44, random.getrandbits(32));
pe.set_dword_at_offset(offset + 48, 0); # age
pe.set_word_at_offset(offset + 52, 0); # null byte for pdbfilename

s.Misc_VirtualSize = 53

# update checksum
pe.OPTIONAL_HEADER.CheckSum == pe.generate_checksum()

# write the modified pe image
pe.write(sys.argv[2])
