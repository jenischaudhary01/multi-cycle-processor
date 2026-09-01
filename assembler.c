#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAX_LINES 200
#define MAX_LEN 100
#define MAX_LABELS 50

char lines[MAX_LINES][MAX_LEN];
int total_lines = 0;

char label_names[MAX_LABELS][50];
int label_addr[MAX_LABELS];
int total_labels = 0;

char output_binary[MAX_LINES][40];
int total_instr = 0;

void to_binary(int num, int bits, char *result) {
    int i;
    for (i = bits - 1; i >= 0; i--) {
        if (num & (1 << i)) result[bits - 1 - i] = '1';
        else result[bits - 1 - i] = '0';
    }
    result[bits] = '\0';
}

int reg_number(char *s) {
    if (s[0] == '$') s++;
    return atoi(s);
}

int is_rtype(char *m) {
    return (strcmp(m,"add")==0 || strcmp(m,"sub")==0 || strcmp(m,"and")==0 ||
            strcmp(m,"or")==0 || strcmp(m,"slt")==0 || strcmp(m,"jr")==0);
}

int is_shift(char *m) {
    return (strcmp(m,"sll")==0 || strcmp(m,"srl")==0);
}

int is_jtype(char *m) {
    return (strcmp(m,"j")==0 || strcmp(m,"jal")==0);
}

int is_zbranch(char *m) {
    return (strcmp(m,"blez")==0 || strcmp(m,"bgtz")==0 ||
            strcmp(m,"bltz")==0 || strcmp(m,"bgez")==0);
}

int get_opcode(char *m) {
    if (strcmp(m,"addi")==0) return 0x08;
    if (strcmp(m,"andi")==0) return 0x0C;
    if (strcmp(m,"ori")==0)  return 0x0D;
    if (strcmp(m,"slti")==0) return 0x0A;
    if (strcmp(m,"lui")==0)  return 0x0F;
    if (strcmp(m,"lw")==0)   return 0x23;
    if (strcmp(m,"sw")==0)   return 0x2B;
    if (strcmp(m,"beq")==0)  return 0x04;
    if (strcmp(m,"bne")==0)  return 0x05;
    if (strcmp(m,"blez")==0) return 0x06;
    if (strcmp(m,"bgtz")==0) return 0x07;
    if (strcmp(m,"bltz")==0) return 0x01;
    if (strcmp(m,"bgez")==0) return 0x01;
    if (strcmp(m,"j")==0)    return 0x02;
    if (strcmp(m,"jal")==0)  return 0x03;
    printf("ERROR: unknown instruction %s\n", m);
    exit(1);
}

int get_funct(char *m) {
    if (strcmp(m,"add")==0) return 0x20;
    if (strcmp(m,"sub")==0) return 0x22;
    if (strcmp(m,"and")==0) return 0x24;
    if (strcmp(m,"or")==0)  return 0x25;
    if (strcmp(m,"slt")==0) return 0x2A;
    if (strcmp(m,"jr")==0)  return 0x08;
    if (strcmp(m,"sll")==0) return 0x00;
    if (strcmp(m,"srl")==0) return 0x02;
    return 0;
}

int find_label(char *name) {
    int i;
    for (i = 0; i < total_labels; i++)
        if (strcmp(label_names[i], name) == 0) return label_addr[i];
    printf("ERROR: label '%s' not found\n", name);
    exit(1);
}

void binary_to_hex(char *binary, char *hexout) {
    unsigned int value = 0;
    int i;
    for (i = 0; i < 32; i++) {
        value = value << 1;
        if (binary[i] == '1') value = value | 1;
    }
    sprintf(hexout, "%08X", value);
}

int main() {
    FILE *fin = fopen("myprogram1.asm", "r");
    FILE *fout = fopen("instruction.hex", "w");

    if (fin == NULL) {
        printf("Could not open myprogram.asm\n");
        return 1;
    }

    while (fgets(lines[total_lines], MAX_LEN, fin) != NULL) {
        int len = strlen(lines[total_lines]);
        if (len > 0 && lines[total_lines][len-1] == '\n') lines[total_lines][len-1] = '\0';
        if (strlen(lines[total_lines]) == 0) continue;
        total_lines++;
    }
    fclose(fin);

    int addr = 0;
    int i;
    for (i = 0; i < total_lines; i++) {
        int len = strlen(lines[i]);
        if (lines[i][len-1] == ':') {
            lines[i][len-1] = '\0';
            strcpy(label_names[total_labels], lines[i]);
            label_addr[total_labels] = addr;
            total_labels++;
            strcpy(lines[i], "");
        } else {
            addr++;
        }
    }

    addr = 0;
    for (i = 0; i < total_lines; i++) {
        if (strlen(lines[i]) == 0) continue;

        char mnemonic[20];
        char a[20], b[20], c[20];
        a[0]=b[0]=c[0]='\0';

        char temp[MAX_LEN];
        strcpy(temp, lines[i]);
        char *token = strtok(temp, " ,");
        strcpy(mnemonic, token);
        token = strtok(NULL, " ,"); if (token) strcpy(a, token);
        token = strtok(NULL, " ,"); if (token) strcpy(b, token);
        token = strtok(NULL, " ,"); if (token) strcpy(c, token);

        char opcode_bin[10], rs_bin[10], rt_bin[10], rd_bin[10];
        char funct_bin[10], shamt_bin[10], imm_bin[20], addr_bin[30];
        char final_binary[40];
        final_binary[0] = '\0';

        if (is_rtype(mnemonic)) {
            int funct = get_funct(mnemonic);
            to_binary(0, 6, opcode_bin);
            to_binary(funct, 6, funct_bin);

            if (strcmp(mnemonic, "jr") == 0) {
                int rs = reg_number(a);
                to_binary(rs, 5, rs_bin);
                to_binary(0, 5, rt_bin);
                to_binary(0, 5, rd_bin);
                to_binary(0, 5, shamt_bin);
            } else {
                int rd = reg_number(a);
                int rs = reg_number(b);
                int rt = reg_number(c);
                to_binary(rs, 5, rs_bin);
                to_binary(rt, 5, rt_bin);
                to_binary(rd, 5, rd_bin);
                to_binary(0, 5, shamt_bin);
            }

            strcat(final_binary, opcode_bin);
            strcat(final_binary, rs_bin);
            strcat(final_binary, rt_bin);
            strcat(final_binary, rd_bin);
            strcat(final_binary, shamt_bin);
            strcat(final_binary, funct_bin);
        }
        else if (is_shift(mnemonic)) {
            int funct = get_funct(mnemonic);
            int rd = reg_number(a);
            int rt = reg_number(b);
            int shamt = atoi(c);

            to_binary(0, 6, opcode_bin);
            to_binary(0, 5, rs_bin);
            to_binary(rt, 5, rt_bin);
            to_binary(rd, 5, rd_bin);
            to_binary(shamt, 5, shamt_bin);
            to_binary(funct, 6, funct_bin);

            strcat(final_binary, opcode_bin);
            strcat(final_binary, rs_bin);
            strcat(final_binary, rt_bin);
            strcat(final_binary, rd_bin);
            strcat(final_binary, shamt_bin);
            strcat(final_binary, funct_bin);
        }
        else if (is_jtype(mnemonic)) {
            int opcode = get_opcode(mnemonic);
            int target = find_label(a);
            to_binary(opcode, 6, opcode_bin);
            to_binary(target, 26, addr_bin);

            strcat(final_binary, opcode_bin);
            strcat(final_binary, addr_bin);
        }
        else if (is_zbranch(mnemonic)) {
            int opcode = get_opcode(mnemonic);
            int rs = reg_number(a);
            int target = find_label(b);
            int offset = target - (addr+1);
            int rt = 0;
            if (strcmp(mnemonic, "bgez") == 0) rt = 1;

            to_binary(opcode, 6, opcode_bin);
            to_binary(rs, 5, rs_bin);
            to_binary(rt, 5, rt_bin);
            to_binary(offset & 0xFFFF, 16, imm_bin);

            strcat(final_binary, opcode_bin);
            strcat(final_binary, rs_bin);
            strcat(final_binary, rt_bin);
            strcat(final_binary, imm_bin);
        }
        else {
            int opcode = get_opcode(mnemonic);
            to_binary(opcode, 6, opcode_bin);

            if (strcmp(mnemonic,"lw")==0 || strcmp(mnemonic,"sw")==0) {
                int rt = reg_number(a);
                char *paren = strchr(b, '(');
                int imm = atoi(b);
                *paren = '\0';
                char *close = strchr(paren+1, ')');
                if (close) *close = '\0';
                int rs = reg_number(paren+1);

                to_binary(rs, 5, rs_bin);
                to_binary(rt, 5, rt_bin);
                to_binary(imm & 0xFFFF, 16, imm_bin);
            }
            else if (strcmp(mnemonic,"beq")==0 || strcmp(mnemonic,"bne")==0) {
                int rs = reg_number(a);
                int rt = reg_number(b);
                int target = find_label(c);
                int offset = target - (addr+1);

                to_binary(rs, 5, rs_bin);
                to_binary(rt, 5, rt_bin);
                to_binary(offset & 0xFFFF, 16, imm_bin);
            }
            else if (strcmp(mnemonic,"lui")==0) {
                int rt = reg_number(a);
                int imm = (int)strtol(b, NULL, 0);
                to_binary(0, 5, rs_bin);
                to_binary(rt, 5, rt_bin);
                to_binary(imm & 0xFFFF, 16, imm_bin);
            }
            else {
                int rt = reg_number(a);
                int rs = reg_number(b);
                int imm = (int)strtol(c, NULL, 0);
                to_binary(rs, 5, rs_bin);
                to_binary(rt, 5, rt_bin);
                to_binary(imm & 0xFFFF, 16, imm_bin);
            }

            strcat(final_binary, opcode_bin);
            strcat(final_binary, rs_bin);
            strcat(final_binary, rt_bin);
            strcat(final_binary, imm_bin);
        }

        strcpy(output_binary[total_instr], final_binary);
        total_instr++;
        addr++;
    }

    for (i = 0; i < total_instr; i++) {
        char hexval[10];
        binary_to_hex(output_binary[i], hexval);
        fprintf(fout, "%s\n", hexval);
    }
    fclose(fout);

    printf("Done! %d instructions written to instruction.hex\n", total_instr);
    return 0;
}
