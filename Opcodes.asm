
.data

align 16
OpPtrs 	dd	Op_0
	dd	Op_1
	dd	Op_2
	dd	Op_3
	dd	Op_4
	dd	Op_5
	dd	Op_6
	dd	Op_7
	dd	Op_8
	dd	Op_9
	dd	Op_A
	dd	Op_B
	dd	Op_C
	dd	Op_D
	dd	Op_E
	dd	Op_F
	dd	Op_10
	dd	Op_11
	dd	Op_12
	dd	Op_13
	dd	Op_14
	dd	Op_15
	dd	Op_16
	dd	Op_17
	dd	Op_18
	dd	Op_19
	dd	Op_1A
	dd	Op_1B
	dd	Op_1C
	dd	Op_1D
	dd	Op_1E
	dd	Op_1F
	dd	Op_20
	dd	Op_21
	dd	Op_22
	dd	Op_23
	dd	Op_24
	dd	Op_25
	dd	Op_26
	dd	Op_27
	dd	Op_28
	dd	Op_29
	dd	Op_2A
	dd	Op_2B
	dd	Op_2C
	dd	Op_2D
	dd	Op_2E
	dd	Op_2F
	dd	Op_30
	dd	Op_31
	dd	Op_32
	dd	Op_33
	dd	Op_34
	dd	Op_35
	dd	Op_36
	dd	Op_37
	dd	Op_38
	dd	Op_39
	dd	Op_3A
	dd	Op_3B
	dd	Op_3C
	dd	Op_3D
	dd	Op_3E
	dd	Op_3F
	dd	Op_40
	dd	Op_41
	dd	Op_42
	dd	Op_43
	dd	Op_44
	dd	Op_45
	dd	Op_46
	dd	Op_47
	dd	Op_48
	dd	Op_49
	dd	Op_4A
	dd	Op_4B
	dd	Op_4C
	dd	Op_4D
	dd	Op_4E
	dd	Op_4F
	dd	Op_50
	dd	Op_51
	dd	Op_52
	dd	Op_53
	dd	Op_54
	dd	Op_55
	dd	Op_56
	dd	Op_57
	dd	Op_58
	dd	Op_59
	dd	Op_5A
	dd	Op_5B
	dd	Op_5C
	dd	Op_5D
	dd	Op_5E
	dd	Op_5F
	dd	Op_60
	dd	Op_61
	dd	Op_62
	dd	Op_63
	dd	Op_64
	dd	Op_65
	dd	Op_66
	dd	Op_67
	dd	Op_68
	dd	Op_69
	dd	Op_6A
	dd	Op_6B
	dd	Op_6C
	dd	Op_6D
	dd	Op_6E
	dd	Op_6F
	dd	Op_70
	dd	Op_71
	dd	Op_72
	dd	Op_73
	dd	Op_74
	dd	Op_75
	dd	Op_76
	dd	Op_77
	dd	Op_78
	dd	Op_79
	dd	Op_7A
	dd	Op_7B
	dd	Op_7C
	dd	Op_7D
	dd	Op_7E
	dd	Op_7F
	dd	Op_80
	dd	Op_81
	dd	Op_82
	dd	Op_83
	dd	Op_84
	dd	Op_85
	dd	Op_86
	dd	Op_87
	dd	Op_88
	dd	Op_89
	dd	Op_8A
	dd	Op_8B
	dd	Op_8C
	dd	Op_8D
	dd	Op_8E
	dd	Op_8F
	dd	Op_90
	dd	Op_91
	dd	Op_92
	dd	Op_93
	dd	Op_94
	dd	Op_95
	dd	Op_96
	dd	Op_97
	dd	Op_98
	dd	Op_99
	dd	Op_9A
	dd	Op_9B
	dd	Op_9C
	dd	Op_9D
	dd	Op_9E
	dd	Op_9F
	dd	Op_A0
	dd	Op_A1
	dd	Op_A2
	dd	Op_A3
	dd	Op_A4
	dd	Op_A5
	dd	Op_A6
	dd	Op_A7
	dd	Op_A8
	dd	Op_A9
	dd	Op_AA
	dd	Op_AB
	dd	Op_AC
	dd	Op_AD
	dd	Op_AE
	dd	Op_AF
	dd	Op_B0
	dd	Op_B1
	dd	Op_B2
	dd	Op_B3
	dd	Op_B4
	dd	Op_B5
	dd	Op_B6
	dd	Op_B7
	dd	Op_B8
	dd	Op_B9
	dd	Op_BA
	dd	Op_BB
	dd	Op_BC
	dd	Op_BD
	dd	Op_BE
	dd	Op_BF
	dd	Op_C0
	dd	Op_C1
	dd	Op_C2
	dd	Op_C3
	dd	Op_C4
	dd	Op_C5
	dd	Op_C6
	dd	Op_C7
	dd	Op_C8
	dd	Op_C9
	dd	Op_CA
	dd	Op_CB
	dd	Op_CC
	dd	Op_CD
	dd	Op_CE
	dd	Op_CF
	dd	Op_D0
	dd	Op_D1
	dd	Op_D2
	dd	Op_D3
	dd	Op_D4
	dd	Op_D5
	dd	Op_D6
	dd	Op_D7
	dd	Op_D8
	dd	Op_D9
	dd	Op_DA
	dd	Op_DB
	dd	Op_DC
	dd	Op_DD
	dd	Op_DE
	dd	Op_DF
	dd	Op_E0
	dd	Op_E1
	dd	Op_E2
	dd	Op_E3
	dd	Op_E4
	dd	Op_E5
	dd	Op_E6
	dd	Op_E7
	dd	Op_E8
	dd	Op_E9
	dd	Op_EA
	dd	Op_EB
	dd	Op_EC
	dd	Op_ED
	dd	Op_EE
	dd	Op_EF
	dd	Op_F0
	dd	Op_F1
	dd	Op_F2
	dd	Op_F3
	dd	Op_F4
	dd	Op_F5
	dd	Op_F6
	dd	Op_F7
	dd	Op_F8
	dd	Op_F9
	dd	Op_FA
	dd	Op_FB
	dd	Op_FC
	dd	Op_FD
	dd	Op_FE
	dd	Op_FF
Op_0 	db	"NOP",0
Op_1 	db	"LD   BC,w",0
Op_2 	db	"LD   (BC),A",0
Op_3 	db	"INC  BC",0
Op_4 	db	"INC  B",0
Op_5 	db	"DEC  B",0
Op_6 	db	"LD   B,q",0
Op_7 	db	"RLCA",0
Op_8 	db	"EX   AF,AF'",0
Op_9 	db	"ADD  HL,BC",0
Op_A 	db	"LD   A,(BC)",0
Op_B 	db	"DEC  BC",0
Op_C 	db	"INC  C",0
Op_D 	db	"DEC  C",0
Op_E 	db	"LD   C,q",0
Op_F 	db	"RRCA",0
Op_10 	db	"|DJNZ e",0
Op_11 	db	"LD   DE,w",0
Op_12 	db	"LD   (DE),A",0
Op_13 	db	"INC  DE",0
Op_14 	db	"INC  D",0
Op_15 	db	"DEC  D",0
Op_16 	db	"LD   D,q",0
Op_17 	db	"RLA",0
Op_18 	db	"|JR   e",0
Op_19 	db	"ADD  HL,DE",0
Op_1A 	db	"LD   A,(DE)",0
Op_1B 	db	"DEC  DE",0
Op_1C 	db	"INC  E",0
Op_1D 	db	"DEC  E",0
Op_1E 	db	"LD   E,q",0
Op_1F 	db	"RRA",0
Op_20 	db	"|JR   NZ,e",0
Op_21 	db	"LD   HL,w",0
Op_22 	db	"LD   (w),HL",0
Op_23 	db	"INC  HL",0
Op_24 	db	"INC  H",0
Op_25 	db	"DEC  H",0
Op_26 	db	"LD   H,q",0
Op_27 	db	"DAA",0
Op_28 	db	"|JR   Z,e",0
Op_29 	db	"ADD  HL,HL",0
Op_2A 	db	"LD   HL,(w)",0
Op_2B 	db	"DEC  HL",0
Op_2C 	db	"INC  L",0
Op_2D 	db	"DEC  L",0
Op_2E 	db	"LD   L,q",0
Op_2F 	db	"CPL",0
Op_30 	db	"|JR   NC,e",0
Op_31 	db	"LD   SP,w",0
Op_32 	db	"LD   (w),A",0
Op_33 	db	"INC  SP",0
Op_34 	db	"INC  (HL)",0
Op_35 	db	"DEC  (HL)",0
Op_36 	db	"LD   (HL),q",0
Op_37 	db	"SCF",0
Op_38 	db	"|JR   C,e",0
Op_39 	db	"ADD  HL,SP",0
Op_3A 	db	"LD   A,(w)",0
Op_3B 	db	"DEC  SP",0
Op_3C 	db	"INC  A",0
Op_3D 	db	"DEC  A",0
Op_3E 	db	"LD   A,q",0
Op_3F 	db	"CCF",0
Op_40 	db	"LD   B,B",0
Op_41 	db	"LD   B,C",0
Op_42 	db	"LD   B,D",0
Op_43 	db	"LD   B,E",0
Op_44 	db	"LD   B,H",0
Op_45 	db	"LD   B,L",0
Op_46 	db	"LD   B,(HL)",0
Op_47 	db	"LD   B,A",0
Op_48 	db	"LD   C,B",0
Op_49 	db	"LD   C,C",0
Op_4A 	db	"LD   C,D",0
Op_4B 	db	"LD   C,E",0
Op_4C 	db	"LD   C,H",0
Op_4D 	db	"LD   C,L",0
Op_4E 	db	"LD   C,(HL)",0
Op_4F 	db	"LD   C,A",0
Op_50 	db	"LD   D,B",0
Op_51 	db	"LD   D,C",0
Op_52 	db	"LD   D,D",0
Op_53 	db	"LD   D,E",0
Op_54 	db	"LD   D,H",0
Op_55 	db	"LD   D,L",0
Op_56 	db	"LD   D,(HL)",0
Op_57 	db	"LD   D,A",0
Op_58 	db	"LD   E,B",0
Op_59 	db	"LD   E,C",0
Op_5A 	db	"LD   E,D",0
Op_5B 	db	"LD   E,E",0
Op_5C 	db	"LD   E,H",0
Op_5D 	db	"LD   E,L",0
Op_5E 	db	"LD   E,(HL)",0
Op_5F 	db	"LD   E,A",0
Op_60 	db	"LD   H,B",0
Op_61 	db	"LD   H,C",0
Op_62 	db	"LD   H,D",0
Op_63 	db	"LD   H,E",0
Op_64 	db	"LD   H,H",0
Op_65 	db	"LD   H,L",0
Op_66 	db	"LD   H,(HL)",0
Op_67 	db	"LD   H,A",0
Op_68 	db	"LD   L,B",0
Op_69 	db	"LD   L,C",0
Op_6A 	db	"LD   L,D",0
Op_6B 	db	"LD   L,E",0
Op_6C 	db	"LD   L,H",0
Op_6D 	db	"LD   L,L",0
Op_6E 	db	"LD   L,(HL)",0
Op_6F 	db	"LD   L,A",0
Op_70 	db	"LD   (HL),B",0
Op_71 	db	"LD   (HL),C",0
Op_72 	db	"LD   (HL),D",0
Op_73 	db	"LD   (HL),E",0
Op_74 	db	"LD   (HL),H",0
Op_75 	db	"LD   (HL),L",0
Op_76 	db	"HALT",0
Op_77 	db	"LD   (HL),A",0
Op_78 	db	"LD   A,B",0
Op_79 	db	"LD   A,C",0
Op_7A 	db	"LD   A,D",0
Op_7B 	db	"LD   A,E",0
Op_7C 	db	"LD   A,H",0
Op_7D 	db	"LD   A,L",0
Op_7E 	db	"LD   A,(HL)",0
Op_7F 	db	"LD   A,A",0
Op_80 	db	"ADD  A,B",0
Op_81 	db	"ADD  A,C",0
Op_82 	db	"ADD  A,D",0
Op_83 	db	"ADD  A,E",0
Op_84 	db	"ADD  A,H",0
Op_85 	db	"ADD  A,L",0
Op_86 	db	"ADD  A,(HL)",0
Op_87 	db	"ADD  A,A",0
Op_88 	db	"ADC  A,B",0
Op_89 	db	"ADC  A,C",0
Op_8A 	db	"ADC  A,D",0
Op_8B 	db	"ADC  A,E",0
Op_8C 	db	"ADC  A,H",0
Op_8D 	db	"ADC  A,L",0
Op_8E 	db	"ADC  A,(HL)",0
Op_8F 	db	"ADC  A,A",0
Op_90 	db	"SUB  B",0
Op_91 	db	"SUB  C",0
Op_92 	db	"SUB  D",0
Op_93 	db	"SUB  E",0
Op_94 	db	"SUB  H",0
Op_95 	db	"SUB  L",0
Op_96 	db	"SUB  (HL)",0
Op_97 	db	"SUB  A",0
Op_98 	db	"SBC  A,B",0
Op_99 	db	"SBC  A,C",0
Op_9A 	db	"SBC  A,D",0
Op_9B 	db	"SBC  A,E",0
Op_9C 	db	"SBC  A,H",0
Op_9D 	db	"SBC  A,L",0
Op_9E 	db	"SBC  A,(HL)",0
Op_9F 	db	"SBC  A,A",0
Op_A0 	db	"AND  B",0
Op_A1 	db	"AND  C",0
Op_A2 	db	"AND  D",0
Op_A3 	db	"AND  E",0
Op_A4 	db	"AND  H",0
Op_A5 	db	"AND  L",0
Op_A6 	db	"AND  (HL)",0
Op_A7 	db	"AND  A",0
Op_A8 	db	"XOR  B",0
Op_A9 	db	"XOR  C",0
Op_AA 	db	"XOR  D",0
Op_AB 	db	"XOR  E",0
Op_AC 	db	"XOR  H",0
Op_AD 	db	"XOR  L",0
Op_AE 	db	"XOR  (HL)",0
Op_AF 	db	"XOR  A",0
Op_B0 	db	"OR   B",0
Op_B1 	db	"OR   C",0
Op_B2 	db	"OR   D",0
Op_B3 	db	"OR   E",0
Op_B4 	db	"OR   H",0
Op_B5 	db	"OR   L",0
Op_B6 	db	"OR   (HL)",0
Op_B7 	db	"OR   A",0
Op_B8 	db	"CP   B",0
Op_B9 	db	"CP   C",0
Op_BA 	db	"CP   D",0
Op_BB 	db	"CP   E",0
Op_BC 	db	"CP   H",0
Op_BD 	db	"CP   L",0
Op_BE 	db	"CP   (HL)",0
Op_BF 	db	"CP   A",0
Op_C0 	db	"|RET  NZ",0
Op_C1 	db	"POP  BC",0
Op_C2 	db	"|JP   NZ,j",0
Op_C3 	db	"|JP   j",0
Op_C4 	db	"CALL NZ,j",0
Op_C5 	db	"PUSH BC",0
Op_C6 	db	"ADD  A,q",0
Op_C7 	db	"RST  r",0
Op_C8 	db	"|RET  Z",0
Op_C9 	db	"|RET",0
Op_CA 	db	"|JP   Z,j",0
Op_CB 	db	"DEFB $CB",0
Op_CC 	db	"CALL Z,j",0
Op_CD 	db	"CALL j",0
Op_CE 	db	"ADC  A,q",0
Op_CF 	db	"RST  r",0
Op_D0 	db	"|RET  NC",0
Op_D1 	db	"POP  DE",0
Op_D2 	db	"|JP   NC,j",0
Op_D3 	db	"OUT  (q),A",0
Op_D4 	db	"CALL NC,j",0
Op_D5 	db	"PUSH DE",0
Op_D6 	db	"SUB  q",0
Op_D7 	db	"RST  r",0
Op_D8 	db	"|RET  C",0
Op_D9 	db	"EXX",0
Op_DA 	db	"|JP   C,j",0
Op_DB 	db	"IN   A,(q)",0
Op_DC 	db	"CALL C,j",0
Op_DD 	db	"DEFB $DD",0
Op_DE 	db	"SBC  A,q",0
Op_DF 	db	"RST  r",0
Op_E0 	db	"|RET  PO",0
Op_E1 	db	"POP  HL",0
Op_E2 	db	"|JP   PO,j",0
Op_E3 	db	"EX   (SP),HL",0
Op_E4 	db	"CALL PO,j",0
Op_E5 	db	"PUSH HL",0
Op_E6 	db	"AND  q",0
Op_E7 	db	"RST  r",0
Op_E8 	db	"|RET  PE",0
Op_E9 	db	"|JP   (HL)",0
Op_EA 	db	"|JP   PE,j",0
Op_EB 	db	"EX   DE,HL",0
Op_EC 	db	"CALL PE,j",0
Op_ED 	db	"DEFB $ED",0
Op_EE 	db	"XOR  q",0
Op_EF 	db	"RST  r",0
Op_F0 	db	"|RET  P",0
Op_F1 	db	"POP  AF",0
Op_F2 	db	"|JP   P,j",0
Op_F3 	db	"DI",0
Op_F4 	db	"CALL P,j",0
Op_F5 	db	"PUSH AF",0
Op_F6 	db	"OR   q",0
Op_F7 	db	"RST  r",0
Op_F8 	db	"|RET  M",0
Op_F9 	db	"LD   SP,HL",0
Op_FA 	db	"|JP   M,j",0
Op_FB 	db	"EI",0
Op_FC 	db	"CALL M,j",0
Op_FD 	db	"DEFB $FD",0
Op_FE 	db	"CP   q",0
Op_FF 	db	"RST  r",0

align 16
DDOpPtrs 	dd	DDOp_0
	dd	DDOp_1
	dd	DDOp_2
	dd	DDOp_3
	dd	DDOp_4
	dd	DDOp_5
	dd	DDOp_6
	dd	DDOp_7
	dd	DDOp_8
	dd	DDOp_9
	dd	DDOp_A
	dd	DDOp_B
	dd	DDOp_C
	dd	DDOp_D
	dd	DDOp_E
	dd	DDOp_F
	dd	DDOp_10
	dd	DDOp_11
	dd	DDOp_12
	dd	DDOp_13
	dd	DDOp_14
	dd	DDOp_15
	dd	DDOp_16
	dd	DDOp_17
	dd	DDOp_18
	dd	DDOp_19
	dd	DDOp_1A
	dd	DDOp_1B
	dd	DDOp_1C
	dd	DDOp_1D
	dd	DDOp_1E
	dd	DDOp_1F
	dd	DDOp_20
	dd	DDOp_21
	dd	DDOp_22
	dd	DDOp_23
	dd	DDOp_24
	dd	DDOp_25
	dd	DDOp_26
	dd	DDOp_27
	dd	DDOp_28
	dd	DDOp_29
	dd	DDOp_2A
	dd	DDOp_2B
	dd	DDOp_2C
	dd	DDOp_2D
	dd	DDOp_2E
	dd	DDOp_2F
	dd	DDOp_30
	dd	DDOp_31
	dd	DDOp_32
	dd	DDOp_33
	dd	DDOp_34
	dd	DDOp_35
	dd	DDOp_36
	dd	DDOp_37
	dd	DDOp_38
	dd	DDOp_39
	dd	DDOp_3A
	dd	DDOp_3B
	dd	DDOp_3C
	dd	DDOp_3D
	dd	DDOp_3E
	dd	DDOp_3F
	dd	DDOp_40
	dd	DDOp_41
	dd	DDOp_42
	dd	DDOp_43
	dd	DDOp_44
	dd	DDOp_45
	dd	DDOp_46
	dd	DDOp_47
	dd	DDOp_48
	dd	DDOp_49
	dd	DDOp_4A
	dd	DDOp_4B
	dd	DDOp_4C
	dd	DDOp_4D
	dd	DDOp_4E
	dd	DDOp_4F
	dd	DDOp_50
	dd	DDOp_51
	dd	DDOp_52
	dd	DDOp_53
	dd	DDOp_54
	dd	DDOp_55
	dd	DDOp_56
	dd	DDOp_57
	dd	DDOp_58
	dd	DDOp_59
	dd	DDOp_5A
	dd	DDOp_5B
	dd	DDOp_5C
	dd	DDOp_5D
	dd	DDOp_5E
	dd	DDOp_5F
	dd	DDOp_60
	dd	DDOp_61
	dd	DDOp_62
	dd	DDOp_63
	dd	DDOp_64
	dd	DDOp_65
	dd	DDOp_66
	dd	DDOp_67
	dd	DDOp_68
	dd	DDOp_69
	dd	DDOp_6A
	dd	DDOp_6B
	dd	DDOp_6C
	dd	DDOp_6D
	dd	DDOp_6E
	dd	DDOp_6F
	dd	DDOp_70
	dd	DDOp_71
	dd	DDOp_72
	dd	DDOp_73
	dd	DDOp_74
	dd	DDOp_75
	dd	DDOp_76
	dd	DDOp_77
	dd	DDOp_78
	dd	DDOp_79
	dd	DDOp_7A
	dd	DDOp_7B
	dd	DDOp_7C
	dd	DDOp_7D
	dd	DDOp_7E
	dd	DDOp_7F
	dd	DDOp_80
	dd	DDOp_81
	dd	DDOp_82
	dd	DDOp_83
	dd	DDOp_84
	dd	DDOp_85
	dd	DDOp_86
	dd	DDOp_87
	dd	DDOp_88
	dd	DDOp_89
	dd	DDOp_8A
	dd	DDOp_8B
	dd	DDOp_8C
	dd	DDOp_8D
	dd	DDOp_8E
	dd	DDOp_8F
	dd	DDOp_90
	dd	DDOp_91
	dd	DDOp_92
	dd	DDOp_93
	dd	DDOp_94
	dd	DDOp_95
	dd	DDOp_96
	dd	DDOp_97
	dd	DDOp_98
	dd	DDOp_99
	dd	DDOp_9A
	dd	DDOp_9B
	dd	DDOp_9C
	dd	DDOp_9D
	dd	DDOp_9E
	dd	DDOp_9F
	dd	DDOp_A0
	dd	DDOp_A1
	dd	DDOp_A2
	dd	DDOp_A3
	dd	DDOp_A4
	dd	DDOp_A5
	dd	DDOp_A6
	dd	DDOp_A7
	dd	DDOp_A8
	dd	DDOp_A9
	dd	DDOp_AA
	dd	DDOp_AB
	dd	DDOp_AC
	dd	DDOp_AD
	dd	DDOp_AE
	dd	DDOp_AF
	dd	DDOp_B0
	dd	DDOp_B1
	dd	DDOp_B2
	dd	DDOp_B3
	dd	DDOp_B4
	dd	DDOp_B5
	dd	DDOp_B6
	dd	DDOp_B7
	dd	DDOp_B8
	dd	DDOp_B9
	dd	DDOp_BA
	dd	DDOp_BB
	dd	DDOp_BC
	dd	DDOp_BD
	dd	DDOp_BE
	dd	DDOp_BF
	dd	DDOp_C0
	dd	DDOp_C1
	dd	DDOp_C2
	dd	DDOp_C3
	dd	DDOp_C4
	dd	DDOp_C5
	dd	DDOp_C6
	dd	DDOp_C7
	dd	DDOp_C8
	dd	DDOp_C9
	dd	DDOp_CA
	dd	DDOp_CB
	dd	DDOp_CC
	dd	DDOp_CD
	dd	DDOp_CE
	dd	DDOp_CF
	dd	DDOp_D0
	dd	DDOp_D1
	dd	DDOp_D2
	dd	DDOp_D3
	dd	DDOp_D4
	dd	DDOp_D5
	dd	DDOp_D6
	dd	DDOp_D7
	dd	DDOp_D8
	dd	DDOp_D9
	dd	DDOp_DA
	dd	DDOp_DB
	dd	DDOp_DC
	dd	DDOp_DD
	dd	DDOp_DE
	dd	DDOp_DF
	dd	DDOp_E0
	dd	DDOp_E1
	dd	DDOp_E2
	dd	DDOp_E3
	dd	DDOp_E4
	dd	DDOp_E5
	dd	DDOp_E6
	dd	DDOp_E7
	dd	DDOp_E8
	dd	DDOp_E9
	dd	DDOp_EA
	dd	DDOp_EB
	dd	DDOp_EC
	dd	DDOp_ED
	dd	DDOp_EE
	dd	DDOp_EF
	dd	DDOp_F0
	dd	DDOp_F1
	dd	DDOp_F2
	dd	DDOp_F3
	dd	DDOp_F4
	dd	DDOp_F5
	dd	DDOp_F6
	dd	DDOp_F7
	dd	DDOp_F8
	dd	DDOp_F9
	dd	DDOp_FA
	dd	DDOp_FB
	dd	DDOp_FC
	dd	DDOp_FD
	dd	DDOp_FE
	dd	DDOp_FF
DDOp_0 	db	"NOP",0
DDOp_1 	db	"LD   BC,w",0
DDOp_2 	db	"LD   (BC),A",0
DDOp_3 	db	"INC  BC",0
DDOp_4 	db	"INC  B",0
DDOp_5 	db	"DEC  B",0
DDOp_6 	db	"LD   B,q",0
DDOp_7 	db	"RLCA",0
DDOp_8 	db	"EX   AF,AF'",0
DDOp_9 	db	"ADD  IX,BC",0
DDOp_A 	db	"LD   A,(BC)",0
DDOp_B 	db	"DEC  BC",0
DDOp_C 	db	"INC  C",0
DDOp_D 	db	"DEC  C",0
DDOp_E 	db	"LD   C,q",0
DDOp_F 	db	"RRCA",0
DDOp_10 	db	"|DJNZ e",0
DDOp_11 	db	"LD   DE,w",0
DDOp_12 	db	"LD   (DE),A",0
DDOp_13 	db	"INC  DE",0
DDOp_14 	db	"INC  D",0
DDOp_15 	db	"DEC  D",0
DDOp_16 	db	"LD   D,q",0
DDOp_17 	db	"RLA",0
DDOp_18 	db	"|JR   e",0
DDOp_19 	db	"ADD  IX,DE",0
DDOp_1A 	db	"LD   A,(DE)",0
DDOp_1B 	db	"DEC  DE",0
DDOp_1C 	db	"INC  E",0
DDOp_1D 	db	"DEC  E",0
DDOp_1E 	db	"LD   E,q",0
DDOp_1F 	db	"RRA",0
DDOp_20 	db	"|JR   NZ,e",0
DDOp_21 	db	"LD   IX,w",0
DDOp_22 	db	"LD   (w),IX",0
DDOp_23 	db	"INC  IX",0
DDOp_24 	db	"INC  IXH",0
DDOp_25 	db	"DEC  IXH",0
DDOp_26 	db	"LD   IXH,q",0
DDOp_27 	db	"DAA",0
DDOp_28 	db	"|JR   Z,e",0
DDOp_29 	db	"ADD  IX,IX",0
DDOp_2A 	db	"LD   IX,(w)",0
DDOp_2B 	db	"DEC  IX",0
DDOp_2C 	db	"INC  IXL",0
DDOp_2D 	db	"DEC  IXL",0
DDOp_2E 	db	"LD   IXL,q",0
DDOp_2F 	db	"CPL",0
DDOp_30 	db	"|JR   NC,e",0
DDOp_31 	db	"LD   SP,w",0
DDOp_32 	db	"LD   (w),A",0
DDOp_33 	db	"INC  SP",0
DDOp_34 	db	"INC  (IX+)",0
DDOp_35 	db	"DEC  (IX+)",0
DDOp_36 	db	"LD   (IX+),q",0
DDOp_37 	db	"SCF",0
DDOp_38 	db	"|JR   C,e",0
DDOp_39 	db	"ADD  IX,SP",0
DDOp_3A 	db	"LD   A,(w)",0
DDOp_3B 	db	"DEC  SP",0
DDOp_3C 	db	"INC  A",0
DDOp_3D 	db	"DEC  A",0
DDOp_3E 	db	"LD   A,q",0
DDOp_3F 	db	"CCF",0
DDOp_40 	db	"LD   B,B",0
DDOp_41 	db	"LD   B,C",0
DDOp_42 	db	"LD   B,D",0
DDOp_43 	db	"LD   B,E",0
DDOp_44 	db	"LD   B,IXH",0
DDOp_45 	db	"LD   B,IXL",0
DDOp_46 	db	"LD   B,(IX+)",0
DDOp_47 	db	"LD   B,A",0
DDOp_48 	db	"LD   C,B",0
DDOp_49 	db	"LD   C,C",0
DDOp_4A 	db	"LD   C,D",0
DDOp_4B 	db	"LD   C,E",0
DDOp_4C 	db	"LD   C,IXH",0
DDOp_4D 	db	"LD   C,IXL",0
DDOp_4E 	db	"LD   C,(IX+)",0
DDOp_4F 	db	"LD   C,A",0
DDOp_50 	db	"LD   D,B",0
DDOp_51 	db	"LD   D,C",0
DDOp_52 	db	"LD   D,D",0
DDOp_53 	db	"LD   D,E",0
DDOp_54 	db	"LD   D,IXH",0
DDOp_55 	db	"LD   D,IXL",0
DDOp_56 	db	"LD   D,(IX+)",0
DDOp_57 	db	"LD   D,A",0
DDOp_58 	db	"LD   E,B",0
DDOp_59 	db	"LD   E,C",0
DDOp_5A 	db	"LD   E,D",0
DDOp_5B 	db	"LD   E,E",0
DDOp_5C 	db	"LD   E,IXH",0
DDOp_5D 	db	"LD   E,IXL",0
DDOp_5E 	db	"LD   E,(IX+)",0
DDOp_5F 	db	"LD   E,A",0
DDOp_60 	db	"LD   IXH,B",0
DDOp_61 	db	"LD   IXH,C",0
DDOp_62 	db	"LD   IXH,D",0
DDOp_63 	db	"LD   IXH,E",0
DDOp_64 	db	"LD   IXH,IXH",0
DDOp_65 	db	"LD   IXH,IXL",0
DDOp_66 	db	"LD   H,(IX+)",0
DDOp_67 	db	"LD   IXH,A",0
DDOp_68 	db	"LD   IXL,B",0
DDOp_69 	db	"LD   IXL,C",0
DDOp_6A 	db	"LD   IXL,D",0
DDOp_6B 	db	"LD   IXL,E",0
DDOp_6C 	db	"LD   IXL,IXH",0
DDOp_6D 	db	"LD   IXL,IXL",0
DDOp_6E 	db	"LD   L,(IX+)",0
DDOp_6F 	db	"LD   IXL,A",0
DDOp_70 	db	"LD   (IX+),B",0
DDOp_71 	db	"LD   (IX+),C",0
DDOp_72 	db	"LD   (IX+),D",0
DDOp_73 	db	"LD   (IX+),E",0
DDOp_74 	db	"LD   (IX+),H",0
DDOp_75 	db	"LD   (IX+),L",0
DDOp_76 	db	"HALT",0
DDOp_77 	db	"LD   (IX+),A",0
DDOp_78 	db	"LD   A,B",0
DDOp_79 	db	"LD   A,C",0
DDOp_7A 	db	"LD   A,D",0
DDOp_7B 	db	"LD   A,E",0
DDOp_7C 	db	"LD   A,IXH",0
DDOp_7D 	db	"LD   A,IXL",0
DDOp_7E 	db	"LD   A,(IX+)",0
DDOp_7F 	db	"LD   A,A",0
DDOp_80 	db	"ADD  A,B",0
DDOp_81 	db	"ADD  A,C",0
DDOp_82 	db	"ADD  A,D",0
DDOp_83 	db	"ADD  A,E",0
DDOp_84 	db	"ADD  A,IXH",0
DDOp_85 	db	"ADD  A,IXL",0
DDOp_86 	db	"ADD  A,(IX+)",0
DDOp_87 	db	"ADD  A,A",0
DDOp_88 	db	"ADC  A,B",0
DDOp_89 	db	"ADC  A,C",0
DDOp_8A 	db	"ADC  A,D",0
DDOp_8B 	db	"ADC  A,E",0
DDOp_8C 	db	"ADC  A,IXH",0
DDOp_8D 	db	"ADC  A,IXL",0
DDOp_8E 	db	"ADC  A,(IX+)",0
DDOp_8F 	db	"ADC  A,A",0
DDOp_90 	db	"SUB  B",0
DDOp_91 	db	"SUB  C",0
DDOp_92 	db	"SUB  D",0
DDOp_93 	db	"SUB  E",0
DDOp_94 	db	"SUB  IXH",0
DDOp_95 	db	"SUB  IXL",0
DDOp_96 	db	"SUB  (IX+)",0
DDOp_97 	db	"SUB  A",0
DDOp_98 	db	"SBC  A,B",0
DDOp_99 	db	"SBC  A,C",0
DDOp_9A 	db	"SBC  A,D",0
DDOp_9B 	db	"SBC  A,E",0
DDOp_9C 	db	"SBC  A,IXH",0
DDOp_9D 	db	"SBC  A,IXL",0
DDOp_9E 	db	"SBC  A,(IX+)",0
DDOp_9F 	db	"SBC  A,A",0
DDOp_A0 	db	"AND  B",0
DDOp_A1 	db	"AND  C",0
DDOp_A2 	db	"AND  D",0
DDOp_A3 	db	"AND  E",0
DDOp_A4 	db	"AND  IXH",0
DDOp_A5 	db	"AND  IXL",0
DDOp_A6 	db	"AND  (IX+)",0
DDOp_A7 	db	"AND  A",0
DDOp_A8 	db	"XOR  B",0
DDOp_A9 	db	"XOR  C",0
DDOp_AA 	db	"XOR  D",0
DDOp_AB 	db	"XOR  E",0
DDOp_AC 	db	"XOR  IXH",0
DDOp_AD 	db	"XOR  IXL",0
DDOp_AE 	db	"XOR  (IX+)",0
DDOp_AF 	db	"XOR  A",0
DDOp_B0 	db	"OR   B",0
DDOp_B1 	db	"OR   C",0
DDOp_B2 	db	"OR   D",0
DDOp_B3 	db	"OR   E",0
DDOp_B4 	db	"OR   IXH",0
DDOp_B5 	db	"OR   IXL",0
DDOp_B6 	db	"OR   (IX+)",0
DDOp_B7 	db	"OR   A",0
DDOp_B8 	db	"CP   B",0
DDOp_B9 	db	"CP   C",0
DDOp_BA 	db	"CP   D",0
DDOp_BB 	db	"CP   E",0
DDOp_BC 	db	"CP   IXH",0
DDOp_BD 	db	"CP   IXL",0
DDOp_BE 	db	"CP   (IX+)",0
DDOp_BF 	db	"CP   A",0
DDOp_C0 	db	"|RET  NZ",0
DDOp_C1 	db	"POP  BC",0
DDOp_C2 	db	"|JP   NZ,j",0
DDOp_C3 	db	"|JP   j",0
DDOp_C4 	db	"CALL NZ,j",0
DDOp_C5 	db	"PUSH BC",0
DDOp_C6 	db	"ADD  A,q",0
DDOp_C7 	db	"RST  r",0
DDOp_C8 	db	"|RET  Z",0
DDOp_C9 	db	"|RET",0
DDOp_CA 	db	"|JP   Z,j",0
DDOp_CB 	db	"DEFB $DD,$CB",0
DDOp_CC 	db	"CALL Z,j",0
DDOp_CD 	db	"CALL j",0
DDOp_CE 	db	"ADC  A,q",0
DDOp_CF 	db	"RST  r",0
DDOp_D0 	db	"|RET  NC",0
DDOp_D1 	db	"POP  DE",0
DDOp_D2 	db	"|JP   NC,j",0
DDOp_D3 	db	"OUT  (q),A",0
DDOp_D4 	db	"CALL NC,j",0
DDOp_D5 	db	"PUSH DE",0
DDOp_D6 	db	"SUB  q",0
DDOp_D7 	db	"RST  r",0
DDOp_D8 	db	"|RET  C",0
DDOp_D9 	db	"EXX",0
DDOp_DA 	db	"|JP   C,j",0
DDOp_DB 	db	"IN   A,(q)",0
DDOp_DC 	db	"CALL C,j",0
DDOp_DD 	db	"DEFB $DD",0
DDOp_DE 	db	"SBC  A,q",0
DDOp_DF 	db	"RST  r",0
DDOp_E0 	db	"|RET  PO",0
DDOp_E1 	db	"POP  IX",0
DDOp_E2 	db	"|JP   PO,j",0
DDOp_E3 	db	"EX   (SP),IX",0
DDOp_E4 	db	"CALL PO,j",0
DDOp_E5 	db	"PUSH IX",0
DDOp_E6 	db	"AND  q",0
DDOp_E7 	db	"RST  r",0
DDOp_E8 	db	"|RET  PE",0
DDOp_E9 	db	"|JP   (IX)",0
DDOp_EA 	db	"|JP   PE,j",0
DDOp_EB 	db	"EX   DE,HL",0
DDOp_EC 	db	"CALL PE,j",0
DDOp_ED 	db	"DEFB $DD",0
DDOp_EE 	db	"XOR  q",0
DDOp_EF 	db	"RST  r",0
DDOp_F0 	db	"|RET  P",0
DDOp_F1 	db	"POP  AF",0
DDOp_F2 	db	"|JP   P,j",0
DDOp_F3 	db	"DI",0
DDOp_F4 	db	"CALL P,j",0
DDOp_F5 	db	"PUSH AF",0
DDOp_F6 	db	"OR   q",0
DDOp_F7 	db	"RST  r",0
DDOp_F8 	db	"|RET  M",0
DDOp_F9 	db	"LD   SP,IX",0
DDOp_FA 	db	"|JP   M,j",0
DDOp_FB 	db	"EI",0
DDOp_FC 	db	"CALL M,j",0
DDOp_FD 	db	"DEFB $DD",0
DDOp_FE 	db	"CP   q",0
DDOp_FF 	db	"RST  r",0

align 16
FDOpPtrs 	dd	FDOp_0
	dd	FDOp_1
	dd	FDOp_2
	dd	FDOp_3
	dd	FDOp_4
	dd	FDOp_5
	dd	FDOp_6
	dd	FDOp_7
	dd	FDOp_8
	dd	FDOp_9
	dd	FDOp_A
	dd	FDOp_B
	dd	FDOp_C
	dd	FDOp_D
	dd	FDOp_E
	dd	FDOp_F
	dd	FDOp_10
	dd	FDOp_11
	dd	FDOp_12
	dd	FDOp_13
	dd	FDOp_14
	dd	FDOp_15
	dd	FDOp_16
	dd	FDOp_17
	dd	FDOp_18
	dd	FDOp_19
	dd	FDOp_1A
	dd	FDOp_1B
	dd	FDOp_1C
	dd	FDOp_1D
	dd	FDOp_1E
	dd	FDOp_1F
	dd	FDOp_20
	dd	FDOp_21
	dd	FDOp_22
	dd	FDOp_23
	dd	FDOp_24
	dd	FDOp_25
	dd	FDOp_26
	dd	FDOp_27
	dd	FDOp_28
	dd	FDOp_29
	dd	FDOp_2A
	dd	FDOp_2B
	dd	FDOp_2C
	dd	FDOp_2D
	dd	FDOp_2E
	dd	FDOp_2F
	dd	FDOp_30
	dd	FDOp_31
	dd	FDOp_32
	dd	FDOp_33
	dd	FDOp_34
	dd	FDOp_35
	dd	FDOp_36
	dd	FDOp_37
	dd	FDOp_38
	dd	FDOp_39
	dd	FDOp_3A
	dd	FDOp_3B
	dd	FDOp_3C
	dd	FDOp_3D
	dd	FDOp_3E
	dd	FDOp_3F
	dd	FDOp_40
	dd	FDOp_41
	dd	FDOp_42
	dd	FDOp_43
	dd	FDOp_44
	dd	FDOp_45
	dd	FDOp_46
	dd	FDOp_47
	dd	FDOp_48
	dd	FDOp_49
	dd	FDOp_4A
	dd	FDOp_4B
	dd	FDOp_4C
	dd	FDOp_4D
	dd	FDOp_4E
	dd	FDOp_4F
	dd	FDOp_50
	dd	FDOp_51
	dd	FDOp_52
	dd	FDOp_53
	dd	FDOp_54
	dd	FDOp_55
	dd	FDOp_56
	dd	FDOp_57
	dd	FDOp_58
	dd	FDOp_59
	dd	FDOp_5A
	dd	FDOp_5B
	dd	FDOp_5C
	dd	FDOp_5D
	dd	FDOp_5E
	dd	FDOp_5F
	dd	FDOp_60
	dd	FDOp_61
	dd	FDOp_62
	dd	FDOp_63
	dd	FDOp_64
	dd	FDOp_65
	dd	FDOp_66
	dd	FDOp_67
	dd	FDOp_68
	dd	FDOp_69
	dd	FDOp_6A
	dd	FDOp_6B
	dd	FDOp_6C
	dd	FDOp_6D
	dd	FDOp_6E
	dd	FDOp_6F
	dd	FDOp_70
	dd	FDOp_71
	dd	FDOp_72
	dd	FDOp_73
	dd	FDOp_74
	dd	FDOp_75
	dd	FDOp_76
	dd	FDOp_77
	dd	FDOp_78
	dd	FDOp_79
	dd	FDOp_7A
	dd	FDOp_7B
	dd	FDOp_7C
	dd	FDOp_7D
	dd	FDOp_7E
	dd	FDOp_7F
	dd	FDOp_80
	dd	FDOp_81
	dd	FDOp_82
	dd	FDOp_83
	dd	FDOp_84
	dd	FDOp_85
	dd	FDOp_86
	dd	FDOp_87
	dd	FDOp_88
	dd	FDOp_89
	dd	FDOp_8A
	dd	FDOp_8B
	dd	FDOp_8C
	dd	FDOp_8D
	dd	FDOp_8E
	dd	FDOp_8F
	dd	FDOp_90
	dd	FDOp_91
	dd	FDOp_92
	dd	FDOp_93
	dd	FDOp_94
	dd	FDOp_95
	dd	FDOp_96
	dd	FDOp_97
	dd	FDOp_98
	dd	FDOp_99
	dd	FDOp_9A
	dd	FDOp_9B
	dd	FDOp_9C
	dd	FDOp_9D
	dd	FDOp_9E
	dd	FDOp_9F
	dd	FDOp_A0
	dd	FDOp_A1
	dd	FDOp_A2
	dd	FDOp_A3
	dd	FDOp_A4
	dd	FDOp_A5
	dd	FDOp_A6
	dd	FDOp_A7
	dd	FDOp_A8
	dd	FDOp_A9
	dd	FDOp_AA
	dd	FDOp_AB
	dd	FDOp_AC
	dd	FDOp_AD
	dd	FDOp_AE
	dd	FDOp_AF
	dd	FDOp_B0
	dd	FDOp_B1
	dd	FDOp_B2
	dd	FDOp_B3
	dd	FDOp_B4
	dd	FDOp_B5
	dd	FDOp_B6
	dd	FDOp_B7
	dd	FDOp_B8
	dd	FDOp_B9
	dd	FDOp_BA
	dd	FDOp_BB
	dd	FDOp_BC
	dd	FDOp_BD
	dd	FDOp_BE
	dd	FDOp_BF
	dd	FDOp_C0
	dd	FDOp_C1
	dd	FDOp_C2
	dd	FDOp_C3
	dd	FDOp_C4
	dd	FDOp_C5
	dd	FDOp_C6
	dd	FDOp_C7
	dd	FDOp_C8
	dd	FDOp_C9
	dd	FDOp_CA
	dd	FDOp_CB
	dd	FDOp_CC
	dd	FDOp_CD
	dd	FDOp_CE
	dd	FDOp_CF
	dd	FDOp_D0
	dd	FDOp_D1
	dd	FDOp_D2
	dd	FDOp_D3
	dd	FDOp_D4
	dd	FDOp_D5
	dd	FDOp_D6
	dd	FDOp_D7
	dd	FDOp_D8
	dd	FDOp_D9
	dd	FDOp_DA
	dd	FDOp_DB
	dd	FDOp_DC
	dd	FDOp_DD
	dd	FDOp_DE
	dd	FDOp_DF
	dd	FDOp_E0
	dd	FDOp_E1
	dd	FDOp_E2
	dd	FDOp_E3
	dd	FDOp_E4
	dd	FDOp_E5
	dd	FDOp_E6
	dd	FDOp_E7
	dd	FDOp_E8
	dd	FDOp_E9
	dd	FDOp_EA
	dd	FDOp_EB
	dd	FDOp_EC
	dd	FDOp_ED
	dd	FDOp_EE
	dd	FDOp_EF
	dd	FDOp_F0
	dd	FDOp_F1
	dd	FDOp_F2
	dd	FDOp_F3
	dd	FDOp_F4
	dd	FDOp_F5
	dd	FDOp_F6
	dd	FDOp_F7
	dd	FDOp_F8
	dd	FDOp_F9
	dd	FDOp_FA
	dd	FDOp_FB
	dd	FDOp_FC
	dd	FDOp_FD
	dd	FDOp_FE
	dd	FDOp_FF
FDOp_0 	db	"NOP",0
FDOp_1 	db	"LD   BC,w",0
FDOp_2 	db	"LD   (BC),A",0
FDOp_3 	db	"INC  BC",0
FDOp_4 	db	"INC  B",0
FDOp_5 	db	"DEC  B",0
FDOp_6 	db	"LD   B,q",0
FDOp_7 	db	"RLCA",0
FDOp_8 	db	"EX   AF,AF'",0
FDOp_9 	db	"ADD  IY,BC",0
FDOp_A 	db	"LD   A,(BC)",0
FDOp_B 	db	"DEC  BC",0
FDOp_C 	db	"INC  C",0
FDOp_D 	db	"DEC  C",0
FDOp_E 	db	"LD   C,q",0
FDOp_F 	db	"RRCA",0
FDOp_10 	db	"|DJNZ e",0
FDOp_11 	db	"LD   DE,w",0
FDOp_12 	db	"LD   (DE),A",0
FDOp_13 	db	"INC  DE",0
FDOp_14 	db	"INC  D",0
FDOp_15 	db	"DEC  D",0
FDOp_16 	db	"LD   D,q",0
FDOp_17 	db	"RLA",0
FDOp_18 	db	"|JR   e",0
FDOp_19 	db	"ADD  IY,DE",0
FDOp_1A 	db	"LD   A,(DE)",0
FDOp_1B 	db	"DEC  DE",0
FDOp_1C 	db	"INC  E",0
FDOp_1D 	db	"DEC  E",0
FDOp_1E 	db	"LD   E,q",0
FDOp_1F 	db	"RRA",0
FDOp_20 	db	"|JR   NZ,e",0
FDOp_21 	db	"LD   IY,w",0
FDOp_22 	db	"LD   (w),IY",0
FDOp_23 	db	"INC  IY",0
FDOp_24 	db	"INC  IYH",0
FDOp_25 	db	"DEC  IYH",0
FDOp_26 	db	"LD   IYH,q",0
FDOp_27 	db	"DAA",0
FDOp_28 	db	"|JR   Z,e",0
FDOp_29 	db	"ADD  IY,IY",0
FDOp_2A 	db	"LD   IY,(w)",0
FDOp_2B 	db	"DEC  IY",0
FDOp_2C 	db	"INC  IYL",0
FDOp_2D 	db	"DEC  IYL",0
FDOp_2E 	db	"LD   IYL,q",0
FDOp_2F 	db	"CPL",0
FDOp_30 	db	"|JR   NC,e",0
FDOp_31 	db	"LD   SP,w",0
FDOp_32 	db	"LD   (w),A",0
FDOp_33 	db	"INC  SP",0
FDOp_34 	db	"INC  (IY+)",0
FDOp_35 	db	"DEC  (IY+)",0
FDOp_36 	db	"LD   (IY+),q",0
FDOp_37 	db	"SCF",0
FDOp_38 	db	"|JR   C,e",0
FDOp_39 	db	"ADD  IY,SP",0
FDOp_3A 	db	"LD   A,(w)",0
FDOp_3B 	db	"DEC  SP",0
FDOp_3C 	db	"INC  A",0
FDOp_3D 	db	"DEC  A",0
FDOp_3E 	db	"LD   A,q",0
FDOp_3F 	db	"CCF",0
FDOp_40 	db	"LD   B,B",0
FDOp_41 	db	"LD   B,C",0
FDOp_42 	db	"LD   B,D",0
FDOp_43 	db	"LD   B,E",0
FDOp_44 	db	"LD   B,IYH",0
FDOp_45 	db	"LD   B,IYL",0
FDOp_46 	db	"LD   B,(IY+)",0
FDOp_47 	db	"LD   B,A",0
FDOp_48 	db	"LD   C,B",0
FDOp_49 	db	"LD   C,C",0
FDOp_4A 	db	"LD   C,D",0
FDOp_4B 	db	"LD   C,E",0
FDOp_4C 	db	"LD   C,IYH",0
FDOp_4D 	db	"LD   C,IYL",0
FDOp_4E 	db	"LD   C,(IY+)",0
FDOp_4F 	db	"LD   C,A",0
FDOp_50 	db	"LD   D,B",0
FDOp_51 	db	"LD   D,C",0
FDOp_52 	db	"LD   D,D",0
FDOp_53 	db	"LD   D,E",0
FDOp_54 	db	"LD   D,IYH",0
FDOp_55 	db	"LD   D,IYL",0
FDOp_56 	db	"LD   D,(IY+)",0
FDOp_57 	db	"LD   D,A",0
FDOp_58 	db	"LD   E,B",0
FDOp_59 	db	"LD   E,C",0
FDOp_5A 	db	"LD   E,D",0
FDOp_5B 	db	"LD   E,E",0
FDOp_5C 	db	"LD   E,IYH",0
FDOp_5D 	db	"LD   E,IYL",0
FDOp_5E 	db	"LD   E,(IY+)",0
FDOp_5F 	db	"LD   E,A",0
FDOp_60 	db	"LD   IYH,B",0
FDOp_61 	db	"LD   IYH,C",0
FDOp_62 	db	"LD   IYH,D",0
FDOp_63 	db	"LD   IYH,E",0
FDOp_64 	db	"LD   IYH,IYH",0
FDOp_65 	db	"LD   IYH,IYL",0
FDOp_66 	db	"LD   H,(IY+)",0
FDOp_67 	db	"LD   IYH,A",0
FDOp_68 	db	"LD   IYL,B",0
FDOp_69 	db	"LD   IYL,C",0
FDOp_6A 	db	"LD   IYL,D",0
FDOp_6B 	db	"LD   IYL,E",0
FDOp_6C 	db	"LD   IYL,IYH",0
FDOp_6D 	db	"LD   IYL,IYL",0
FDOp_6E 	db	"LD   L,(IY+)",0
FDOp_6F 	db	"LD   IYL,A",0
FDOp_70 	db	"LD   (IY+),B",0
FDOp_71 	db	"LD   (IY+),C",0
FDOp_72 	db	"LD   (IY+),D",0
FDOp_73 	db	"LD   (IY+),E",0
FDOp_74 	db	"LD   (IY+),H",0
FDOp_75 	db	"LD   (IY+),L",0
FDOp_76 	db	"HALT",0
FDOp_77 	db	"LD   (IY+),A",0
FDOp_78 	db	"LD   A,B",0
FDOp_79 	db	"LD   A,C",0
FDOp_7A 	db	"LD   A,D",0
FDOp_7B 	db	"LD   A,E",0
FDOp_7C 	db	"LD   A,IYH",0
FDOp_7D 	db	"LD   A,IYL",0
FDOp_7E 	db	"LD   A,(IY+)",0
FDOp_7F 	db	"LD   A,A",0
FDOp_80 	db	"ADD  A,B",0
FDOp_81 	db	"ADD  A,C",0
FDOp_82 	db	"ADD  A,D",0
FDOp_83 	db	"ADD  A,E",0
FDOp_84 	db	"ADD  A,IYH",0
FDOp_85 	db	"ADD  A,IYL",0
FDOp_86 	db	"ADD  A,(IY+)",0
FDOp_87 	db	"ADD  A,A",0
FDOp_88 	db	"ADC  A,B",0
FDOp_89 	db	"ADC  A,C",0
FDOp_8A 	db	"ADC  A,D",0
FDOp_8B 	db	"ADC  A,E",0
FDOp_8C 	db	"ADC  A,IYH",0
FDOp_8D 	db	"ADC  A,IYL",0
FDOp_8E 	db	"ADC  A,(IY+)",0
FDOp_8F 	db	"ADC  A,A",0
FDOp_90 	db	"SUB  B",0
FDOp_91 	db	"SUB  C",0
FDOp_92 	db	"SUB  D",0
FDOp_93 	db	"SUB  E",0
FDOp_94 	db	"SUB  IYH",0
FDOp_95 	db	"SUB  IYL",0
FDOp_96 	db	"SUB  (IY+)",0
FDOp_97 	db	"SUB  A",0
FDOp_98 	db	"SBC  A,B",0
FDOp_99 	db	"SBC  A,C",0
FDOp_9A 	db	"SBC  A,D",0
FDOp_9B 	db	"SBC  A,E",0
FDOp_9C 	db	"SBC  A,IYH",0
FDOp_9D 	db	"SBC  A,IYL",0
FDOp_9E 	db	"SBC  A,(IY+)",0
FDOp_9F 	db	"SBC  A,A",0
FDOp_A0 	db	"AND  B",0
FDOp_A1 	db	"AND  C",0
FDOp_A2 	db	"AND  D",0
FDOp_A3 	db	"AND  E",0
FDOp_A4 	db	"AND  IYH",0
FDOp_A5 	db	"AND  IYL",0
FDOp_A6 	db	"AND  (IY+)",0
FDOp_A7 	db	"AND  A",0
FDOp_A8 	db	"XOR  B",0
FDOp_A9 	db	"XOR  C",0
FDOp_AA 	db	"XOR  D",0
FDOp_AB 	db	"XOR  E",0
FDOp_AC 	db	"XOR  IYH",0
FDOp_AD 	db	"XOR  IYL",0
FDOp_AE 	db	"XOR  (IY+)",0
FDOp_AF 	db	"XOR  A",0
FDOp_B0 	db	"OR   B",0
FDOp_B1 	db	"OR   C",0
FDOp_B2 	db	"OR   D",0
FDOp_B3 	db	"OR   E",0
FDOp_B4 	db	"OR   IYH",0
FDOp_B5 	db	"OR   IYL",0
FDOp_B6 	db	"OR   (IY+)",0
FDOp_B7 	db	"OR   A",0
FDOp_B8 	db	"CP   B",0
FDOp_B9 	db	"CP   C",0
FDOp_BA 	db	"CP   D",0
FDOp_BB 	db	"CP   E",0
FDOp_BC 	db	"CP   IYH",0
FDOp_BD 	db	"CP   IYL",0
FDOp_BE 	db	"CP   (IY+)",0
FDOp_BF 	db	"CP   A",0
FDOp_C0 	db	"|RET  NZ",0
FDOp_C1 	db	"POP  BC",0
FDOp_C2 	db	"|JP   NZ,j",0
FDOp_C3 	db	"|JP   j",0
FDOp_C4 	db	"CALL NZ,j",0
FDOp_C5 	db	"PUSH BC",0
FDOp_C6 	db	"ADD  A,q",0
FDOp_C7 	db	"RST  r",0
FDOp_C8 	db	"|RET  Z",0
FDOp_C9 	db	"|RET",0
FDOp_CA 	db	"|JP   Z,j",0
FDOp_CB 	db	"DEFB $DD,$CB",0
FDOp_CC 	db	"CALL Z,j",0
FDOp_CD 	db	"CALL j",0
FDOp_CE 	db	"ADC  A,q",0
FDOp_CF 	db	"RST  r",0
FDOp_D0 	db	"|RET  NC",0
FDOp_D1 	db	"POP  DE",0
FDOp_D2 	db	"|JP   NC,j",0
FDOp_D3 	db	"OUT  (q),A",0
FDOp_D4 	db	"CALL NC,j",0
FDOp_D5 	db	"PUSH DE",0
FDOp_D6 	db	"SUB  q",0
FDOp_D7 	db	"RST  r",0
FDOp_D8 	db	"|RET  C",0
FDOp_D9 	db	"EXX",0
FDOp_DA 	db	"|JP   C,j",0
FDOp_DB 	db	"IN   A,(q)",0
FDOp_DC 	db	"CALL C,j",0
FDOp_DD 	db	"DEFB $FD",0
FDOp_DE 	db	"SBC  A,q",0
FDOp_DF 	db	"RST  r",0
FDOp_E0 	db	"|RET  PO",0
FDOp_E1 	db	"POP  IY",0
FDOp_E2 	db	"|JP   PO,j",0
FDOp_E3 	db	"EX   (SP),IY",0
FDOp_E4 	db	"CALL PO,j",0
FDOp_E5 	db	"PUSH IY",0
FDOp_E6 	db	"AND  q",0
FDOp_E7 	db	"RST  r",0
FDOp_E8 	db	"|RET  PE",0
FDOp_E9 	db	"|JP   (IY)",0
FDOp_EA 	db	"|JP   PE,j",0
FDOp_EB 	db	"EX   DE,HL",0
FDOp_EC 	db	"CALL PE,j",0
FDOp_ED 	db	"DEFB $FD",0
FDOp_EE 	db	"XOR  q",0
FDOp_EF 	db	"RST  r",0
FDOp_F0 	db	"|RET  P",0
FDOp_F1 	db	"POP  AF",0
FDOp_F2 	db	"|JP   P,j",0
FDOp_F3 	db	"DI",0
FDOp_F4 	db	"CALL P,j",0
FDOp_F5 	db	"PUSH AF",0
FDOp_F6 	db	"OR   q",0
FDOp_F7 	db	"RST  r",0
FDOp_F8 	db	"|RET  M",0
FDOp_F9 	db	"LD   SP,IY",0
FDOp_FA 	db	"|JP   M,j",0
FDOp_FB 	db	"EI",0
FDOp_FC 	db	"CALL M,j",0
FDOp_FD 	db	"DEFB $FD",0
FDOp_FE 	db	"CP   q",0
FDOp_FF 	db	"RST  r",0

align 16
EDOpPtrs 	dd	EDOp_0
	dd	EDOp_1
	dd	EDOp_2
	dd	EDOp_3
	dd	EDOp_4
	dd	EDOp_5
	dd	EDOp_6
	dd	EDOp_7
	dd	EDOp_8
	dd	EDOp_9
	dd	EDOp_A
	dd	EDOp_B
	dd	EDOp_C
	dd	EDOp_D
	dd	EDOp_E
	dd	EDOp_F
	dd	EDOp_10
	dd	EDOp_11
	dd	EDOp_12
	dd	EDOp_13
	dd	EDOp_14
	dd	EDOp_15
	dd	EDOp_16
	dd	EDOp_17
	dd	EDOp_18
	dd	EDOp_19
	dd	EDOp_1A
	dd	EDOp_1B
	dd	EDOp_1C
	dd	EDOp_1D
	dd	EDOp_1E
	dd	EDOp_1F
	dd	EDOp_20
	dd	EDOp_21
	dd	EDOp_22
	dd	EDOp_23
	dd	EDOp_24
	dd	EDOp_25
	dd	EDOp_26
	dd	EDOp_27
	dd	EDOp_28
	dd	EDOp_29
	dd	EDOp_2A
	dd	EDOp_2B
	dd	EDOp_2C
	dd	EDOp_2D
	dd	EDOp_2E
	dd	EDOp_2F
	dd	EDOp_30
	dd	EDOp_31
	dd	EDOp_32
	dd	EDOp_33
	dd	EDOp_34
	dd	EDOp_35
	dd	EDOp_36
	dd	EDOp_37
	dd	EDOp_38
	dd	EDOp_39
	dd	EDOp_3A
	dd	EDOp_3B
	dd	EDOp_3C
	dd	EDOp_3D
	dd	EDOp_3E
	dd	EDOp_3F
	dd	EDOp_40
	dd	EDOp_41
	dd	EDOp_42
	dd	EDOp_43
	dd	EDOp_44
	dd	EDOp_45
	dd	EDOp_46
	dd	EDOp_47
	dd	EDOp_48
	dd	EDOp_49
	dd	EDOp_4A
	dd	EDOp_4B
	dd	EDOp_4C
	dd	EDOp_4D
	dd	EDOp_4E
	dd	EDOp_4F
	dd	EDOp_50
	dd	EDOp_51
	dd	EDOp_52
	dd	EDOp_53
	dd	EDOp_54
	dd	EDOp_55
	dd	EDOp_56
	dd	EDOp_57
	dd	EDOp_58
	dd	EDOp_59
	dd	EDOp_5A
	dd	EDOp_5B
	dd	EDOp_5C
	dd	EDOp_5D
	dd	EDOp_5E
	dd	EDOp_5F
	dd	EDOp_60
	dd	EDOp_61
	dd	EDOp_62
	dd	EDOp_63
	dd	EDOp_64
	dd	EDOp_65
	dd	EDOp_66
	dd	EDOp_67
	dd	EDOp_68
	dd	EDOp_69
	dd	EDOp_6A
	dd	EDOp_6B
	dd	EDOp_6C
	dd	EDOp_6D
	dd	EDOp_6E
	dd	EDOp_6F
	dd	EDOp_70
	dd	EDOp_71
	dd	EDOp_72
	dd	EDOp_73
	dd	EDOp_74
	dd	EDOp_75
	dd	EDOp_76
	dd	EDOp_77
	dd	EDOp_78
	dd	EDOp_79
	dd	EDOp_7A
	dd	EDOp_7B
	dd	EDOp_7C
	dd	EDOp_7D
	dd	EDOp_7E
	dd	EDOp_7F
	dd	EDOp_80
	dd	EDOp_81
	dd	EDOp_82
	dd	EDOp_83
	dd	EDOp_84
	dd	EDOp_85
	dd	EDOp_86
	dd	EDOp_87
	dd	EDOp_88
	dd	EDOp_89
	dd	EDOp_8A
	dd	EDOp_8B
	dd	EDOp_8C
	dd	EDOp_8D
	dd	EDOp_8E
	dd	EDOp_8F
	dd	EDOp_90
	dd	EDOp_91
	dd	EDOp_92
	dd	EDOp_93
	dd	EDOp_94
	dd	EDOp_95
	dd	EDOp_96
	dd	EDOp_97
	dd	EDOp_98
	dd	EDOp_99
	dd	EDOp_9A
	dd	EDOp_9B
	dd	EDOp_9C
	dd	EDOp_9D
	dd	EDOp_9E
	dd	EDOp_9F
	dd	EDOp_A0
	dd	EDOp_A1
	dd	EDOp_A2
	dd	EDOp_A3
	dd	EDOp_A4
	dd	EDOp_A5
	dd	EDOp_A6
	dd	EDOp_A7
	dd	EDOp_A8
	dd	EDOp_A9
	dd	EDOp_AA
	dd	EDOp_AB
	dd	EDOp_AC
	dd	EDOp_AD
	dd	EDOp_AE
	dd	EDOp_AF
	dd	EDOp_B0
	dd	EDOp_B1
	dd	EDOp_B2
	dd	EDOp_B3
	dd	EDOp_B4
	dd	EDOp_B5
	dd	EDOp_B6
	dd	EDOp_B7
	dd	EDOp_B8
	dd	EDOp_B9
	dd	EDOp_BA
	dd	EDOp_BB
	dd	EDOp_BC
	dd	EDOp_BD
	dd	EDOp_BE
	dd	EDOp_BF
	dd	EDOp_C0
	dd	EDOp_C1
	dd	EDOp_C2
	dd	EDOp_C3
	dd	EDOp_C4
	dd	EDOp_C5
	dd	EDOp_C6
	dd	EDOp_C7
	dd	EDOp_C8
	dd	EDOp_C9
	dd	EDOp_CA
	dd	EDOp_CB
	dd	EDOp_CC
	dd	EDOp_CD
	dd	EDOp_CE
	dd	EDOp_CF
	dd	EDOp_D0
	dd	EDOp_D1
	dd	EDOp_D2
	dd	EDOp_D3
	dd	EDOp_D4
	dd	EDOp_D5
	dd	EDOp_D6
	dd	EDOp_D7
	dd	EDOp_D8
	dd	EDOp_D9
	dd	EDOp_DA
	dd	EDOp_DB
	dd	EDOp_DC
	dd	EDOp_DD
	dd	EDOp_DE
	dd	EDOp_DF
	dd	EDOp_E0
	dd	EDOp_E1
	dd	EDOp_E2
	dd	EDOp_E3
	dd	EDOp_E4
	dd	EDOp_E5
	dd	EDOp_E6
	dd	EDOp_E7
	dd	EDOp_E8
	dd	EDOp_E9
	dd	EDOp_EA
	dd	EDOp_EB
	dd	EDOp_EC
	dd	EDOp_ED
	dd	EDOp_EE
	dd	EDOp_EF
	dd	EDOp_F0
	dd	EDOp_F1
	dd	EDOp_F2
	dd	EDOp_F3
	dd	EDOp_F4
	dd	EDOp_F5
	dd	EDOp_F6
	dd	EDOp_F7
	dd	EDOp_F8
	dd	EDOp_F9
	dd	EDOp_FA
	dd	EDOp_FB
	dd	EDOp_FC
	dd	EDOp_FD
	dd	EDOp_FE
	dd	EDOp_FF
EDOp_0 	db	"DEFB $ED,$00",0
EDOp_1 	db	"DEFB $ED,$01",0
EDOp_2 	db	"DEFB $ED,$02",0
EDOp_3 	db	"DEFB $ED,$03",0
EDOp_4 	db	"DEFB $ED,$04",0
EDOp_5 	db	"DEFB $ED,$05",0
EDOp_6 	db	"DEFB $ED,$06",0
EDOp_7 	db	"DEFB $ED,$07",0
EDOp_8 	db	"DEFB $ED,$08",0
EDOp_9 	db	"DEFB $ED,$09",0
EDOp_A 	db	"DEFB $ED,$0A",0
EDOp_B 	db	"DEFB $ED,$0B",0
EDOp_C 	db	"DEFB $ED,$0C",0
EDOp_D 	db	"DEFB $ED,$0D",0
EDOp_E 	db	"DEFB $ED,$0E",0
EDOp_F 	db	"DEFB $ED,$0F",0
EDOp_10 	db	"DEFB $ED,$10",0
EDOp_11 	db	"DEFB $ED,$11",0
EDOp_12 	db	"DEFB $ED,$12",0
EDOp_13 	db	"DEFB $ED,$13",0
EDOp_14 	db	"DEFB $ED,$14",0
EDOp_15 	db	"DEFB $ED,$15",0
EDOp_16 	db	"DEFB $ED,$16",0
EDOp_17 	db	"DEFB $ED,$17",0
EDOp_18 	db	"DEFB $ED,$18",0
EDOp_19 	db	"DEFB $ED,$19",0
EDOp_1A 	db	"DEFB $ED,$1A",0
EDOp_1B 	db	"DEFB $ED,$1B",0
EDOp_1C 	db	"DEFB $ED,$1C",0
EDOp_1D 	db	"DEFB $ED,$1D",0
EDOp_1E 	db	"DEFB $ED,$1E",0
EDOp_1F 	db	"DEFB $ED,$1F",0
EDOp_20 	db	"DEFB $ED,$20",0
EDOp_21 	db	"DEFB $ED,$21",0
EDOp_22 	db	"DEFB $ED,$22",0
EDOp_23 	db	"DEFB $ED,$23",0
EDOp_24 	db	"DEFB $ED,$24",0
EDOp_25 	db	"DEFB $ED,$25",0
EDOp_26 	db	"DEFB $ED,$26",0
EDOp_27 	db	"DEFB $ED,$27",0
EDOp_28 	db	"DEFB $ED,$28",0
EDOp_29 	db	"DEFB $ED,$29",0
EDOp_2A 	db	"DEFB $ED,$2A",0
EDOp_2B 	db	"DEFB $ED,$2B",0
EDOp_2C 	db	"DEFB $ED,$2C",0
EDOp_2D 	db	"DEFB $ED,$2D",0
EDOp_2E 	db	"DEFB $ED,$2E",0
EDOp_2F 	db	"DEFB $ED,$2F",0
EDOp_30 	db	"DEFB $ED,$30",0
EDOp_31 	db	"DEFB $ED,$31",0
EDOp_32 	db	"DEFB $ED,$32",0
EDOp_33 	db	"DEFB $ED,$33",0
EDOp_34 	db	"DEFB $ED,$34",0
EDOp_35 	db	"DEFB $ED,$35",0
EDOp_36 	db	"DEFB $ED,$36",0
EDOp_37 	db	"DEFB $ED,$37",0
EDOp_38 	db	"DEFB $ED,$38",0
EDOp_39 	db	"DEFB $ED,$39",0
EDOp_3A 	db	"DEFB $ED,$3A",0
EDOp_3B 	db	"DEFB $ED,$3B",0
EDOp_3C 	db	"DEFB $ED,$3C",0
EDOp_3D 	db	"DEFB $ED,$3D",0
EDOp_3E 	db	"DEFB $ED,$3E",0
EDOp_3F 	db	"DEFB $ED,$3F",0
EDOp_40 	db	"IN   B,(C)",0
EDOp_41 	db	"OUT  (C),B",0
EDOp_42 	db	"SBC  HL,BC",0
EDOp_43 	db	"LD   (w),BC",0
EDOp_44 	db	"NEG",0
EDOp_45 	db	"|RETN",0
EDOp_46 	db	"IM   0",0
EDOp_47 	db	"LD   I,A",0
EDOp_48 	db	"IN   C,(C)",0
EDOp_49 	db	"OUT  (C),C",0
EDOp_4A 	db	"ADC  HL,BC",0
EDOp_4B 	db	"LD   BC,(w)",0
EDOp_4C 	db	"NEG",0
EDOp_4D 	db	"|RETI",0
EDOp_4E 	db	"IM   0/1",0
EDOp_4F 	db	"LD   R,A",0
EDOp_50 	db	"IN   D,(C)",0
EDOp_51 	db	"OUT  (C),D",0
EDOp_52 	db	"SBC  HL,DE",0
EDOp_53 	db	"LD   (w),DE",0
EDOp_54 	db	"NEG",0
EDOp_55 	db	"|RETN",0
EDOp_56 	db	"IM   1",0
EDOp_57 	db	"LD   A,I",0
EDOp_58 	db	"IN   E,(C)",0
EDOp_59 	db	"OUT  (C),E",0
EDOp_5A 	db	"ADC  HL,DE",0
EDOp_5B 	db	"LD   DE,(w)",0
EDOp_5C 	db	"NEG",0
EDOp_5D 	db	"|RETN",0
EDOp_5E 	db	"IM   2",0
EDOp_5F 	db	"LD   A,R",0
EDOp_60 	db	"IN   H,(C)",0
EDOp_61 	db	"OUT  (C),H",0
EDOp_62 	db	"SBC  HL,HL",0
EDOp_63 	db	"LD   (w),HL",0
EDOp_64 	db	"NEG",0
EDOp_65 	db	"|RETN",0
EDOp_66 	db	"IM   0/1",0
EDOp_67 	db	"RRD",0
EDOp_68 	db	"IN   L,(C)",0
EDOp_69 	db	"OUT  (C),L",0
EDOp_6A 	db	"ADC  HL,HL",0
EDOp_6B 	db	"LD   HL,(w)",0
EDOp_6C 	db	"NEG",0
EDOp_6D 	db	"|RETN",0
EDOp_6E 	db	"IM   0/1",0
EDOp_6F 	db	"RLD",0
EDOp_70 	db	"IN   F,(C)",0
EDOp_71 	db	"OUT  (C),0",0
EDOp_72 	db	"SBC  HL,SP",0
EDOp_73 	db	"LD   (w),SP",0
EDOp_74 	db	"NEG",0
EDOp_75 	db	"|RETN",0
EDOp_76 	db	"IM   1",0
EDOp_77 	db	"DEFB $ED,$77",0
EDOp_78 	db	"IN   A,(C)",0
EDOp_79 	db	"OUT  (C),A",0
EDOp_7A 	db	"ADC  HL,SP",0
EDOp_7B 	db	"LD   SP,(w)",0
EDOp_7C 	db	"NEG",0
EDOp_7D 	db	"|RETN",0
EDOp_7E 	db	"IM   2",0
EDOp_7F 	db	"DEFB $ED,$7F",0
EDOp_80 	db	"DEFB $ED,$80",0
EDOp_81 	db	"DEFB $ED,$81",0
EDOp_82 	db	"DEFB $ED,$82",0
EDOp_83 	db	"DEFB $ED,$83",0
EDOp_84 	db	"DEFB $ED,$84",0
EDOp_85 	db	"DEFB $ED,$85",0
EDOp_86 	db	"DEFB $ED,$86",0
EDOp_87 	db	"DEFB $ED,$87",0
EDOp_88 	db	"DEFB $ED,$88",0
EDOp_89 	db	"DEFB $ED,$89",0
EDOp_8A 	db	"DEFB $ED,$8A",0
EDOp_8B 	db	"DEFB $ED,$8B",0
EDOp_8C 	db	"DEFB $ED,$8C",0
EDOp_8D 	db	"DEFB $ED,$8D",0
EDOp_8E 	db	"DEFB $ED,$8E",0
EDOp_8F 	db	"DEFB $ED,$8F",0
EDOp_90 	db	"DEFB $ED,$90",0
EDOp_91 	db	"DEFB $ED,$91",0
EDOp_92 	db	"DEFB $ED,$92",0
EDOp_93 	db	"DEFB $ED,$93",0
EDOp_94 	db	"DEFB $ED,$94",0
EDOp_95 	db	"DEFB $ED,$95",0
EDOp_96 	db	"DEFB $ED,$96",0
EDOp_97 	db	"DEFB $ED,$97",0
EDOp_98 	db	"DEFB $ED,$98",0
EDOp_99 	db	"DEFB $ED,$99",0
EDOp_9A 	db	"DEFB $ED,$9A",0
EDOp_9B 	db	"DEFB $ED,$9B",0
EDOp_9C 	db	"DEFB $ED,$9C",0
EDOp_9D 	db	"DEFB $ED,$9D",0
EDOp_9E 	db	"DEFB $ED,$9E",0
EDOp_9F 	db	"DEFB $ED,$9F",0
EDOp_A0 	db	"LDI",0
EDOp_A1 	db	"CPI",0
EDOp_A2 	db	"INI",0
EDOp_A3 	db	"OUTI",0
EDOp_A4 	db	"DEFB $ED,$A4",0
EDOp_A5 	db	"DEFB $ED,$A5",0
EDOp_A6 	db	"DEFB $ED,$A6",0
EDOp_A7 	db	"DEFB $ED,$A7",0
EDOp_A8 	db	"LDD",0
EDOp_A9 	db	"CPD",0
EDOp_AA 	db	"IND",0
EDOp_AB 	db	"OUTD",0
EDOp_AC 	db	"DEFB $ED,$AC",0
EDOp_AD 	db	"DEFB $ED,$AD",0
EDOp_AE 	db	"DEFB $ED,$AE",0
EDOp_AF 	db	"DEFB $ED,$AF",0
EDOp_B0 	db	"LDIR",0
EDOp_B1 	db	"CPIR",0
EDOp_B2 	db	"INIR",0
EDOp_B3 	db	"OTIR",0
EDOp_B4 	db	"DEFB $ED,$B4",0
EDOp_B5 	db	"DEFB $ED,$B5",0
EDOp_B6 	db	"DEFB $ED,$B6",0
EDOp_B7 	db	"DEFB $ED,$B7",0
EDOp_B8 	db	"LDDR",0
EDOp_B9 	db	"CPDR",0
EDOp_BA 	db	"INDR",0
EDOp_BB 	db	"OTDR",0
EDOp_BC 	db	"DEFB $ED,$BC",0
EDOp_BD 	db	"DEFB $ED,$BD",0
EDOp_BE 	db	"DEFB $ED,$BE",0
EDOp_BF 	db	"DEFB $ED,$BF",0
EDOp_C0 	db	"DEFB $ED,$C0",0
EDOp_C1 	db	"DEFB $ED,$C1",0
EDOp_C2 	db	"DEFB $ED,$C2",0
EDOp_C3 	db	"DEFB $ED,$C3",0
EDOp_C4 	db	"DEFB $ED,$C4",0
EDOp_C5 	db	"DEFB $ED,$C5",0
EDOp_C6 	db	"DEFB $ED,$C6",0
EDOp_C7 	db	"DEFB $ED,$C7",0
EDOp_C8 	db	"DEFB $ED,$C8",0
EDOp_C9 	db	"DEFB $ED,$C9",0
EDOp_CA 	db	"DEFB $ED,$CA",0
EDOp_CB 	db	"DEFB $ED,$CB",0
EDOp_CC 	db	"DEFB $ED,$CC",0
EDOp_CD 	db	"DEFB $ED,$CD",0
EDOp_CE 	db	"DEFB $ED,$CE",0
EDOp_CF 	db	"DEFB $ED,$CF",0
EDOp_D0 	db	"DEFB $ED,$D0",0
EDOp_D1 	db	"DEFB $ED,$D1",0
EDOp_D2 	db	"DEFB $ED,$D2",0
EDOp_D3 	db	"DEFB $ED,$D3",0
EDOp_D4 	db	"DEFB $ED,$D4",0
EDOp_D5 	db	"DEFB $ED,$D5",0
EDOp_D6 	db	"DEFB $ED,$D6",0
EDOp_D7 	db	"DEFB $ED,$D7",0
EDOp_D8 	db	"DEFB $ED,$D8",0
EDOp_D9 	db	"DEFB $ED,$D9",0
EDOp_DA 	db	"DEFB $ED,$DA",0
EDOp_DB 	db	"DEFB $ED,$DB",0
EDOp_DC 	db	"DEFB $ED,$DC",0
EDOp_DD 	db	"DEFB $ED,$DD",0
EDOp_DE 	db	"DEFB $ED,$DE",0
EDOp_DF 	db	"DEFB $ED,$DF",0
EDOp_E0 	db	"DEFB $ED,$E0",0
EDOp_E1 	db	"DEFB $ED,$E1",0
EDOp_E2 	db	"DEFB $ED,$E2",0
EDOp_E3 	db	"DEFB $ED,$E3",0
EDOp_E4 	db	"DEFB $ED,$E4",0
EDOp_E5 	db	"DEFB $ED,$E5",0
EDOp_E6 	db	"DEFB $ED,$E6",0
EDOp_E7 	db	"DEFB $ED,$E7",0
EDOp_E8 	db	"DEFB $ED,$E8",0
EDOp_E9 	db	"DEFB $ED,$E9",0
EDOp_EA 	db	"DEFB $ED,$EA",0
EDOp_EB 	db	"DEFB $ED,$EB",0
EDOp_EC 	db	"DEFB $ED,$EC",0
EDOp_ED 	db	"DEFB $ED,$ED",0
EDOp_EE 	db	"DEFB $ED,$EE",0
EDOp_EF 	db	"DEFB $ED,$EF",0
EDOp_F0 	db	"DEFB $ED,$F0",0
EDOp_F1 	db	"DEFB $ED,$F1",0
EDOp_F2 	db	"DEFB $ED,$F2",0
EDOp_F3 	db	"DEFB $ED,$F3",0
EDOp_F4 	db	"DEFB $ED,$F4",0
EDOp_F5 	db	"DEFB $ED,$F5",0
EDOp_F6 	db	"DEFB $ED,$F6",0
EDOp_F7 	db	"DEFB $ED,$F7",0
EDOp_F8 	db	"DEFB $ED,$F8",0
EDOp_F9 	db	"DEFB $ED,$F9",0
EDOp_FA 	db	"DEFB $ED,$FA",0
EDOp_FB 	db	"DEFB $ED,$FB",0
EDOp_FC 	db	"DEFB $ED,$FC",0
EDOp_FD 	db	"DEFB $ED,$FD",0
EDOp_FE 	db	"DEFB $ED,$FE",0
EDOp_FF 	db	"DEFB $ED,$FF",0

align 16
CBOpPtrs 	dd	CBOp_0
	dd	CBOp_1
	dd	CBOp_2
	dd	CBOp_3
	dd	CBOp_4
	dd	CBOp_5
	dd	CBOp_6
	dd	CBOp_7
	dd	CBOp_8
	dd	CBOp_9
	dd	CBOp_A
	dd	CBOp_B
	dd	CBOp_C
	dd	CBOp_D
	dd	CBOp_E
	dd	CBOp_F
	dd	CBOp_10
	dd	CBOp_11
	dd	CBOp_12
	dd	CBOp_13
	dd	CBOp_14
	dd	CBOp_15
	dd	CBOp_16
	dd	CBOp_17
	dd	CBOp_18
	dd	CBOp_19
	dd	CBOp_1A
	dd	CBOp_1B
	dd	CBOp_1C
	dd	CBOp_1D
	dd	CBOp_1E
	dd	CBOp_1F
	dd	CBOp_20
	dd	CBOp_21
	dd	CBOp_22
	dd	CBOp_23
	dd	CBOp_24
	dd	CBOp_25
	dd	CBOp_26
	dd	CBOp_27
	dd	CBOp_28
	dd	CBOp_29
	dd	CBOp_2A
	dd	CBOp_2B
	dd	CBOp_2C
	dd	CBOp_2D
	dd	CBOp_2E
	dd	CBOp_2F
	dd	CBOp_30
	dd	CBOp_31
	dd	CBOp_32
	dd	CBOp_33
	dd	CBOp_34
	dd	CBOp_35
	dd	CBOp_36
	dd	CBOp_37
	dd	CBOp_38
	dd	CBOp_39
	dd	CBOp_3A
	dd	CBOp_3B
	dd	CBOp_3C
	dd	CBOp_3D
	dd	CBOp_3E
	dd	CBOp_3F
	dd	CBOp_40
	dd	CBOp_41
	dd	CBOp_42
	dd	CBOp_43
	dd	CBOp_44
	dd	CBOp_45
	dd	CBOp_46
	dd	CBOp_47
	dd	CBOp_48
	dd	CBOp_49
	dd	CBOp_4A
	dd	CBOp_4B
	dd	CBOp_4C
	dd	CBOp_4D
	dd	CBOp_4E
	dd	CBOp_4F
	dd	CBOp_50
	dd	CBOp_51
	dd	CBOp_52
	dd	CBOp_53
	dd	CBOp_54
	dd	CBOp_55
	dd	CBOp_56
	dd	CBOp_57
	dd	CBOp_58
	dd	CBOp_59
	dd	CBOp_5A
	dd	CBOp_5B
	dd	CBOp_5C
	dd	CBOp_5D
	dd	CBOp_5E
	dd	CBOp_5F
	dd	CBOp_60
	dd	CBOp_61
	dd	CBOp_62
	dd	CBOp_63
	dd	CBOp_64
	dd	CBOp_65
	dd	CBOp_66
	dd	CBOp_67
	dd	CBOp_68
	dd	CBOp_69
	dd	CBOp_6A
	dd	CBOp_6B
	dd	CBOp_6C
	dd	CBOp_6D
	dd	CBOp_6E
	dd	CBOp_6F
	dd	CBOp_70
	dd	CBOp_71
	dd	CBOp_72
	dd	CBOp_73
	dd	CBOp_74
	dd	CBOp_75
	dd	CBOp_76
	dd	CBOp_77
	dd	CBOp_78
	dd	CBOp_79
	dd	CBOp_7A
	dd	CBOp_7B
	dd	CBOp_7C
	dd	CBOp_7D
	dd	CBOp_7E
	dd	CBOp_7F
	dd	CBOp_80
	dd	CBOp_81
	dd	CBOp_82
	dd	CBOp_83
	dd	CBOp_84
	dd	CBOp_85
	dd	CBOp_86
	dd	CBOp_87
	dd	CBOp_88
	dd	CBOp_89
	dd	CBOp_8A
	dd	CBOp_8B
	dd	CBOp_8C
	dd	CBOp_8D
	dd	CBOp_8E
	dd	CBOp_8F
	dd	CBOp_90
	dd	CBOp_91
	dd	CBOp_92
	dd	CBOp_93
	dd	CBOp_94
	dd	CBOp_95
	dd	CBOp_96
	dd	CBOp_97
	dd	CBOp_98
	dd	CBOp_99
	dd	CBOp_9A
	dd	CBOp_9B
	dd	CBOp_9C
	dd	CBOp_9D
	dd	CBOp_9E
	dd	CBOp_9F
	dd	CBOp_A0
	dd	CBOp_A1
	dd	CBOp_A2
	dd	CBOp_A3
	dd	CBOp_A4
	dd	CBOp_A5
	dd	CBOp_A6
	dd	CBOp_A7
	dd	CBOp_A8
	dd	CBOp_A9
	dd	CBOp_AA
	dd	CBOp_AB
	dd	CBOp_AC
	dd	CBOp_AD
	dd	CBOp_AE
	dd	CBOp_AF
	dd	CBOp_B0
	dd	CBOp_B1
	dd	CBOp_B2
	dd	CBOp_B3
	dd	CBOp_B4
	dd	CBOp_B5
	dd	CBOp_B6
	dd	CBOp_B7
	dd	CBOp_B8
	dd	CBOp_B9
	dd	CBOp_BA
	dd	CBOp_BB
	dd	CBOp_BC
	dd	CBOp_BD
	dd	CBOp_BE
	dd	CBOp_BF
	dd	CBOp_C0
	dd	CBOp_C1
	dd	CBOp_C2
	dd	CBOp_C3
	dd	CBOp_C4
	dd	CBOp_C5
	dd	CBOp_C6
	dd	CBOp_C7
	dd	CBOp_C8
	dd	CBOp_C9
	dd	CBOp_CA
	dd	CBOp_CB
	dd	CBOp_CC
	dd	CBOp_CD
	dd	CBOp_CE
	dd	CBOp_CF
	dd	CBOp_D0
	dd	CBOp_D1
	dd	CBOp_D2
	dd	CBOp_D3
	dd	CBOp_D4
	dd	CBOp_D5
	dd	CBOp_D6
	dd	CBOp_D7
	dd	CBOp_D8
	dd	CBOp_D9
	dd	CBOp_DA
	dd	CBOp_DB
	dd	CBOp_DC
	dd	CBOp_DD
	dd	CBOp_DE
	dd	CBOp_DF
	dd	CBOp_E0
	dd	CBOp_E1
	dd	CBOp_E2
	dd	CBOp_E3
	dd	CBOp_E4
	dd	CBOp_E5
	dd	CBOp_E6
	dd	CBOp_E7
	dd	CBOp_E8
	dd	CBOp_E9
	dd	CBOp_EA
	dd	CBOp_EB
	dd	CBOp_EC
	dd	CBOp_ED
	dd	CBOp_EE
	dd	CBOp_EF
	dd	CBOp_F0
	dd	CBOp_F1
	dd	CBOp_F2
	dd	CBOp_F3
	dd	CBOp_F4
	dd	CBOp_F5
	dd	CBOp_F6
	dd	CBOp_F7
	dd	CBOp_F8
	dd	CBOp_F9
	dd	CBOp_FA
	dd	CBOp_FB
	dd	CBOp_FC
	dd	CBOp_FD
	dd	CBOp_FE
	dd	CBOp_FF
CBOp_0 	db	"RLC  B",0
CBOp_1 	db	"RLC  C",0
CBOp_2 	db	"RLC  D",0
CBOp_3 	db	"RLC  E",0
CBOp_4 	db	"RLC  H",0
CBOp_5 	db	"RLC  L",0
CBOp_6 	db	"RLC  (HL)",0
CBOp_7 	db	"RLC  A",0
CBOp_8 	db	"RRC  B",0
CBOp_9 	db	"RRC  C",0
CBOp_A 	db	"RRC  D",0
CBOp_B 	db	"RRC  E",0
CBOp_C 	db	"RRC  H",0
CBOp_D 	db	"RRC  L",0
CBOp_E 	db	"RRC  (HL)",0
CBOp_F 	db	"RRC  A",0
CBOp_10 	db	"RL   B",0
CBOp_11 	db	"RL   C",0
CBOp_12 	db	"RL   D",0
CBOp_13 	db	"RL   E",0
CBOp_14 	db	"RL   H",0
CBOp_15 	db	"RL   L",0
CBOp_16 	db	"RL   (HL)",0
CBOp_17 	db	"RL   A",0
CBOp_18 	db	"RR   B",0
CBOp_19 	db	"RR   C",0
CBOp_1A 	db	"RR   D",0
CBOp_1B 	db	"RR   E",0
CBOp_1C 	db	"RR   H",0
CBOp_1D 	db	"RR   L",0
CBOp_1E 	db	"RR   (HL)",0
CBOp_1F 	db	"RR   A",0
CBOp_20 	db	"SLA  B",0
CBOp_21 	db	"SLA  C",0
CBOp_22 	db	"SLA  D",0
CBOp_23 	db	"SLA  E",0
CBOp_24 	db	"SLA  H",0
CBOp_25 	db	"SLA  L",0
CBOp_26 	db	"SLA  (HL)",0
CBOp_27 	db	"SLA  A",0
CBOp_28 	db	"SRA  B",0
CBOp_29 	db	"SRA  C",0
CBOp_2A 	db	"SRA  D",0
CBOp_2B 	db	"SRA  E",0
CBOp_2C 	db	"SRA  H",0
CBOp_2D 	db	"SRA  L",0
CBOp_2E 	db	"SRA  (HL)",0
CBOp_2F 	db	"SRA  A",0
CBOp_30 	db	"SLL  B",0
CBOp_31 	db	"SLL  C",0
CBOp_32 	db	"SLL  D",0
CBOp_33 	db	"SLL  E",0
CBOp_34 	db	"SLL  H",0
CBOp_35 	db	"SLL  L",0
CBOp_36 	db	"SLL  (HL)",0
CBOp_37 	db	"SLL  A",0
CBOp_38 	db	"SRL  B",0
CBOp_39 	db	"SRL  C",0
CBOp_3A 	db	"SRL  D",0
CBOp_3B 	db	"SRL  E",0
CBOp_3C 	db	"SRL  H",0
CBOp_3D 	db	"SRL  L",0
CBOp_3E 	db	"SRL  (HL)",0
CBOp_3F 	db	"SRL  A",0
CBOp_40 	db	"BIT  0,B",0
CBOp_41 	db	"BIT  0,C",0
CBOp_42 	db	"BIT  0,D",0
CBOp_43 	db	"BIT  0,E",0
CBOp_44 	db	"BIT  0,H",0
CBOp_45 	db	"BIT  0,L",0
CBOp_46 	db	"BIT  0,(HL)",0
CBOp_47 	db	"BIT  0,A",0
CBOp_48 	db	"BIT  1,B",0
CBOp_49 	db	"BIT  1,C",0
CBOp_4A 	db	"BIT  1,D",0
CBOp_4B 	db	"BIT  1,E",0
CBOp_4C 	db	"BIT  1,H",0
CBOp_4D 	db	"BIT  1,L",0
CBOp_4E 	db	"BIT  1,(HL)",0
CBOp_4F 	db	"BIT  1,A",0
CBOp_50 	db	"BIT  2,B",0
CBOp_51 	db	"BIT  2,C",0
CBOp_52 	db	"BIT  2,D",0
CBOp_53 	db	"BIT  2,E",0
CBOp_54 	db	"BIT  2,H",0
CBOp_55 	db	"BIT  2,L",0
CBOp_56 	db	"BIT  2,(HL)",0
CBOp_57 	db	"BIT  2,A",0
CBOp_58 	db	"BIT  3,B",0
CBOp_59 	db	"BIT  3,C",0
CBOp_5A 	db	"BIT  3,D",0
CBOp_5B 	db	"BIT  3,E",0
CBOp_5C 	db	"BIT  3,H",0
CBOp_5D 	db	"BIT  3,L",0
CBOp_5E 	db	"BIT  3,(HL)",0
CBOp_5F 	db	"BIT  3,A",0
CBOp_60 	db	"BIT  4,B",0
CBOp_61 	db	"BIT  4,C",0
CBOp_62 	db	"BIT  4,D",0
CBOp_63 	db	"BIT  4,E",0
CBOp_64 	db	"BIT  4,H",0
CBOp_65 	db	"BIT  4,L",0
CBOp_66 	db	"BIT  4,(HL)",0
CBOp_67 	db	"BIT  4,A",0
CBOp_68 	db	"BIT  5,B",0
CBOp_69 	db	"BIT  5,C",0
CBOp_6A 	db	"BIT  5,D",0
CBOp_6B 	db	"BIT  5,E",0
CBOp_6C 	db	"BIT  5,H",0
CBOp_6D 	db	"BIT  5,L",0
CBOp_6E 	db	"BIT  5,(HL)",0
CBOp_6F 	db	"BIT  5,A",0
CBOp_70 	db	"BIT  6,B",0
CBOp_71 	db	"BIT  6,C",0
CBOp_72 	db	"BIT  6,D",0
CBOp_73 	db	"BIT  6,E",0
CBOp_74 	db	"BIT  6,H",0
CBOp_75 	db	"BIT  6,L",0
CBOp_76 	db	"BIT  6,(HL)",0
CBOp_77 	db	"BIT  6,A",0
CBOp_78 	db	"BIT  7,B",0
CBOp_79 	db	"BIT  7,C",0
CBOp_7A 	db	"BIT  7,D",0
CBOp_7B 	db	"BIT  7,E",0
CBOp_7C 	db	"BIT  7,H",0
CBOp_7D 	db	"BIT  7,L",0
CBOp_7E 	db	"BIT  7,(HL)",0
CBOp_7F 	db	"BIT  7,A",0
CBOp_80 	db	"RES  0,B",0
CBOp_81 	db	"RES  0,C",0
CBOp_82 	db	"RES  0,D",0
CBOp_83 	db	"RES  0,E",0
CBOp_84 	db	"RES  0,H",0
CBOp_85 	db	"RES  0,L",0
CBOp_86 	db	"RES  0,(HL)",0
CBOp_87 	db	"RES  0,A",0
CBOp_88 	db	"RES  1,B",0
CBOp_89 	db	"RES  1,C",0
CBOp_8A 	db	"RES  1,D",0
CBOp_8B 	db	"RES  1,E",0
CBOp_8C 	db	"RES  1,H",0
CBOp_8D 	db	"RES  1,L",0
CBOp_8E 	db	"RES  1,(HL)",0
CBOp_8F 	db	"RES  1,A",0
CBOp_90 	db	"RES  2,B",0
CBOp_91 	db	"RES  2,C",0
CBOp_92 	db	"RES  2,D",0
CBOp_93 	db	"RES  2,E",0
CBOp_94 	db	"RES  2,H",0
CBOp_95 	db	"RES  2,L",0
CBOp_96 	db	"RES  2,(HL)",0
CBOp_97 	db	"RES  2,A",0
CBOp_98 	db	"RES  3,B",0
CBOp_99 	db	"RES  3,C",0
CBOp_9A 	db	"RES  3,D",0
CBOp_9B 	db	"RES  3,E",0
CBOp_9C 	db	"RES  3,H",0
CBOp_9D 	db	"RES  3,L",0
CBOp_9E 	db	"RES  3,(HL)",0
CBOp_9F 	db	"RES  3,A",0
CBOp_A0 	db	"RES  4,B",0
CBOp_A1 	db	"RES  4,C",0
CBOp_A2 	db	"RES  4,D",0
CBOp_A3 	db	"RES  4,E",0
CBOp_A4 	db	"RES  4,H",0
CBOp_A5 	db	"RES  4,L",0
CBOp_A6 	db	"RES  4,(HL)",0
CBOp_A7 	db	"RES  4,A",0
CBOp_A8 	db	"RES  5,B",0
CBOp_A9 	db	"RES  5,C",0
CBOp_AA 	db	"RES  5,D",0
CBOp_AB 	db	"RES  5,E",0
CBOp_AC 	db	"RES  5,H",0
CBOp_AD 	db	"RES  5,L",0
CBOp_AE 	db	"RES  5,(HL)",0
CBOp_AF 	db	"RES  5,A",0
CBOp_B0 	db	"RES  6,B",0
CBOp_B1 	db	"RES  6,C",0
CBOp_B2 	db	"RES  6,D",0
CBOp_B3 	db	"RES  6,E",0
CBOp_B4 	db	"RES  6,H",0
CBOp_B5 	db	"RES  6,L",0
CBOp_B6 	db	"RES  6,(HL)",0
CBOp_B7 	db	"RES  6,A",0
CBOp_B8 	db	"RES  7,B",0
CBOp_B9 	db	"RES  7,C",0
CBOp_BA 	db	"RES  7,D",0
CBOp_BB 	db	"RES  7,E",0
CBOp_BC 	db	"RES  7,H",0
CBOp_BD 	db	"RES  7,L",0
CBOp_BE 	db	"RES  7,(HL)",0
CBOp_BF 	db	"RES  7,A",0
CBOp_C0 	db	"SET  0,B",0
CBOp_C1 	db	"SET  0,C",0
CBOp_C2 	db	"SET  0,D",0
CBOp_C3 	db	"SET  0,E",0
CBOp_C4 	db	"SET  0,H",0
CBOp_C5 	db	"SET  0,L",0
CBOp_C6 	db	"SET  0,(HL)",0
CBOp_C7 	db	"SET  0,A",0
CBOp_C8 	db	"SET  1,B",0
CBOp_C9 	db	"SET  1,C",0
CBOp_CA 	db	"SET  1,D",0
CBOp_CB 	db	"SET  1,E",0
CBOp_CC 	db	"SET  1,H",0
CBOp_CD 	db	"SET  1,L",0
CBOp_CE 	db	"SET  1,(HL)",0
CBOp_CF 	db	"SET  1,A",0
CBOp_D0 	db	"SET  2,B",0
CBOp_D1 	db	"SET  2,C",0
CBOp_D2 	db	"SET  2,D",0
CBOp_D3 	db	"SET  2,E",0
CBOp_D4 	db	"SET  2,H",0
CBOp_D5 	db	"SET  2,L",0
CBOp_D6 	db	"SET  2,(HL)",0
CBOp_D7 	db	"SET  2,A",0
CBOp_D8 	db	"SET  3,B",0
CBOp_D9 	db	"SET  3,C",0
CBOp_DA 	db	"SET  3,D",0
CBOp_DB 	db	"SET  3,E",0
CBOp_DC 	db	"SET  3,H",0
CBOp_DD 	db	"SET  3,L",0
CBOp_DE 	db	"SET  3,(HL)",0
CBOp_DF 	db	"SET  3,A",0
CBOp_E0 	db	"SET  4,B",0
CBOp_E1 	db	"SET  4,C",0
CBOp_E2 	db	"SET  4,D",0
CBOp_E3 	db	"SET  4,E",0
CBOp_E4 	db	"SET  4,H",0
CBOp_E5 	db	"SET  4,L",0
CBOp_E6 	db	"SET  4,(HL)",0
CBOp_E7 	db	"SET  4,A",0
CBOp_E8 	db	"SET  5,B",0
CBOp_E9 	db	"SET  5,C",0
CBOp_EA 	db	"SET  5,D",0
CBOp_EB 	db	"SET  5,E",0
CBOp_EC 	db	"SET  5,H",0
CBOp_ED 	db	"SET  5,L",0
CBOp_EE 	db	"SET  5,(HL)",0
CBOp_EF 	db	"SET  5,A",0
CBOp_F0 	db	"SET  6,B",0
CBOp_F1 	db	"SET  6,C",0
CBOp_F2 	db	"SET  6,D",0
CBOp_F3 	db	"SET  6,E",0
CBOp_F4 	db	"SET  6,H",0
CBOp_F5 	db	"SET  6,L",0
CBOp_F6 	db	"SET  6,(HL)",0
CBOp_F7 	db	"SET  6,A",0
CBOp_F8 	db	"SET  7,B",0
CBOp_F9 	db	"SET  7,C",0
CBOp_FA 	db	"SET  7,D",0
CBOp_FB 	db	"SET  7,E",0
CBOp_FC 	db	"SET  7,H",0
CBOp_FD 	db	"SET  7,L",0
CBOp_FE 	db	"SET  7,(HL)",0
CBOp_FF 	db	"SET  7,A",0

align 16
DDCBOpPtrs 	dd	DDCBOp_0
	dd	DDCBOp_1
	dd	DDCBOp_2
	dd	DDCBOp_3
	dd	DDCBOp_4
	dd	DDCBOp_5
	dd	DDCBOp_6
	dd	DDCBOp_7
	dd	DDCBOp_8
	dd	DDCBOp_9
	dd	DDCBOp_A
	dd	DDCBOp_B
	dd	DDCBOp_C
	dd	DDCBOp_D
	dd	DDCBOp_E
	dd	DDCBOp_F
	dd	DDCBOp_10
	dd	DDCBOp_11
	dd	DDCBOp_12
	dd	DDCBOp_13
	dd	DDCBOp_14
	dd	DDCBOp_15
	dd	DDCBOp_16
	dd	DDCBOp_17
	dd	DDCBOp_18
	dd	DDCBOp_19
	dd	DDCBOp_1A
	dd	DDCBOp_1B
	dd	DDCBOp_1C
	dd	DDCBOp_1D
	dd	DDCBOp_1E
	dd	DDCBOp_1F
	dd	DDCBOp_20
	dd	DDCBOp_21
	dd	DDCBOp_22
	dd	DDCBOp_23
	dd	DDCBOp_24
	dd	DDCBOp_25
	dd	DDCBOp_26
	dd	DDCBOp_27
	dd	DDCBOp_28
	dd	DDCBOp_29
	dd	DDCBOp_2A
	dd	DDCBOp_2B
	dd	DDCBOp_2C
	dd	DDCBOp_2D
	dd	DDCBOp_2E
	dd	DDCBOp_2F
	dd	DDCBOp_30
	dd	DDCBOp_31
	dd	DDCBOp_32
	dd	DDCBOp_33
	dd	DDCBOp_34
	dd	DDCBOp_35
	dd	DDCBOp_36
	dd	DDCBOp_37
	dd	DDCBOp_38
	dd	DDCBOp_39
	dd	DDCBOp_3A
	dd	DDCBOp_3B
	dd	DDCBOp_3C
	dd	DDCBOp_3D
	dd	DDCBOp_3E
	dd	DDCBOp_3F
	dd	DDCBOp_40
	dd	DDCBOp_41
	dd	DDCBOp_42
	dd	DDCBOp_43
	dd	DDCBOp_44
	dd	DDCBOp_45
	dd	DDCBOp_46
	dd	DDCBOp_47
	dd	DDCBOp_48
	dd	DDCBOp_49
	dd	DDCBOp_4A
	dd	DDCBOp_4B
	dd	DDCBOp_4C
	dd	DDCBOp_4D
	dd	DDCBOp_4E
	dd	DDCBOp_4F
	dd	DDCBOp_50
	dd	DDCBOp_51
	dd	DDCBOp_52
	dd	DDCBOp_53
	dd	DDCBOp_54
	dd	DDCBOp_55
	dd	DDCBOp_56
	dd	DDCBOp_57
	dd	DDCBOp_58
	dd	DDCBOp_59
	dd	DDCBOp_5A
	dd	DDCBOp_5B
	dd	DDCBOp_5C
	dd	DDCBOp_5D
	dd	DDCBOp_5E
	dd	DDCBOp_5F
	dd	DDCBOp_60
	dd	DDCBOp_61
	dd	DDCBOp_62
	dd	DDCBOp_63
	dd	DDCBOp_64
	dd	DDCBOp_65
	dd	DDCBOp_66
	dd	DDCBOp_67
	dd	DDCBOp_68
	dd	DDCBOp_69
	dd	DDCBOp_6A
	dd	DDCBOp_6B
	dd	DDCBOp_6C
	dd	DDCBOp_6D
	dd	DDCBOp_6E
	dd	DDCBOp_6F
	dd	DDCBOp_70
	dd	DDCBOp_71
	dd	DDCBOp_72
	dd	DDCBOp_73
	dd	DDCBOp_74
	dd	DDCBOp_75
	dd	DDCBOp_76
	dd	DDCBOp_77
	dd	DDCBOp_78
	dd	DDCBOp_79
	dd	DDCBOp_7A
	dd	DDCBOp_7B
	dd	DDCBOp_7C
	dd	DDCBOp_7D
	dd	DDCBOp_7E
	dd	DDCBOp_7F
	dd	DDCBOp_80
	dd	DDCBOp_81
	dd	DDCBOp_82
	dd	DDCBOp_83
	dd	DDCBOp_84
	dd	DDCBOp_85
	dd	DDCBOp_86
	dd	DDCBOp_87
	dd	DDCBOp_88
	dd	DDCBOp_89
	dd	DDCBOp_8A
	dd	DDCBOp_8B
	dd	DDCBOp_8C
	dd	DDCBOp_8D
	dd	DDCBOp_8E
	dd	DDCBOp_8F
	dd	DDCBOp_90
	dd	DDCBOp_91
	dd	DDCBOp_92
	dd	DDCBOp_93
	dd	DDCBOp_94
	dd	DDCBOp_95
	dd	DDCBOp_96
	dd	DDCBOp_97
	dd	DDCBOp_98
	dd	DDCBOp_99
	dd	DDCBOp_9A
	dd	DDCBOp_9B
	dd	DDCBOp_9C
	dd	DDCBOp_9D
	dd	DDCBOp_9E
	dd	DDCBOp_9F
	dd	DDCBOp_A0
	dd	DDCBOp_A1
	dd	DDCBOp_A2
	dd	DDCBOp_A3
	dd	DDCBOp_A4
	dd	DDCBOp_A5
	dd	DDCBOp_A6
	dd	DDCBOp_A7
	dd	DDCBOp_A8
	dd	DDCBOp_A9
	dd	DDCBOp_AA
	dd	DDCBOp_AB
	dd	DDCBOp_AC
	dd	DDCBOp_AD
	dd	DDCBOp_AE
	dd	DDCBOp_AF
	dd	DDCBOp_B0
	dd	DDCBOp_B1
	dd	DDCBOp_B2
	dd	DDCBOp_B3
	dd	DDCBOp_B4
	dd	DDCBOp_B5
	dd	DDCBOp_B6
	dd	DDCBOp_B7
	dd	DDCBOp_B8
	dd	DDCBOp_B9
	dd	DDCBOp_BA
	dd	DDCBOp_BB
	dd	DDCBOp_BC
	dd	DDCBOp_BD
	dd	DDCBOp_BE
	dd	DDCBOp_BF
	dd	DDCBOp_C0
	dd	DDCBOp_C1
	dd	DDCBOp_C2
	dd	DDCBOp_C3
	dd	DDCBOp_C4
	dd	DDCBOp_C5
	dd	DDCBOp_C6
	dd	DDCBOp_C7
	dd	DDCBOp_C8
	dd	DDCBOp_C9
	dd	DDCBOp_CA
	dd	DDCBOp_CB
	dd	DDCBOp_CC
	dd	DDCBOp_CD
	dd	DDCBOp_CE
	dd	DDCBOp_CF
	dd	DDCBOp_D0
	dd	DDCBOp_D1
	dd	DDCBOp_D2
	dd	DDCBOp_D3
	dd	DDCBOp_D4
	dd	DDCBOp_D5
	dd	DDCBOp_D6
	dd	DDCBOp_D7
	dd	DDCBOp_D8
	dd	DDCBOp_D9
	dd	DDCBOp_DA
	dd	DDCBOp_DB
	dd	DDCBOp_DC
	dd	DDCBOp_DD
	dd	DDCBOp_DE
	dd	DDCBOp_DF
	dd	DDCBOp_E0
	dd	DDCBOp_E1
	dd	DDCBOp_E2
	dd	DDCBOp_E3
	dd	DDCBOp_E4
	dd	DDCBOp_E5
	dd	DDCBOp_E6
	dd	DDCBOp_E7
	dd	DDCBOp_E8
	dd	DDCBOp_E9
	dd	DDCBOp_EA
	dd	DDCBOp_EB
	dd	DDCBOp_EC
	dd	DDCBOp_ED
	dd	DDCBOp_EE
	dd	DDCBOp_EF
	dd	DDCBOp_F0
	dd	DDCBOp_F1
	dd	DDCBOp_F2
	dd	DDCBOp_F3
	dd	DDCBOp_F4
	dd	DDCBOp_F5
	dd	DDCBOp_F6
	dd	DDCBOp_F7
	dd	DDCBOp_F8
	dd	DDCBOp_F9
	dd	DDCBOp_FA
	dd	DDCBOp_FB
	dd	DDCBOp_FC
	dd	DDCBOp_FD
	dd	DDCBOp_FE
	dd	DDCBOp_FF
DDCBOp_0 	db	"LD   B,RLC (IX+)",0
DDCBOp_1 	db	"LD   C,RLC (IX+)",0
DDCBOp_2 	db	"LD   D,RLC (IX+)",0
DDCBOp_3 	db	"LD   E,RLC (IX+)",0
DDCBOp_4 	db	"LD   H,RLC (IX+)",0
DDCBOp_5 	db	"LD   L,RLC (IX+)",0
DDCBOp_6 	db	"RLC  (IX+)",0
DDCBOp_7 	db	"LD   A,RLC (IX+)",0
DDCBOp_8 	db	"LD   B,RRC (IX+)",0
DDCBOp_9 	db	"LD   C,RRC (IX+)",0
DDCBOp_A 	db	"LD   D,RRC (IX+)",0
DDCBOp_B 	db	"LD   E,RRC (IX+)",0
DDCBOp_C 	db	"LD   H,RRC (IX+)",0
DDCBOp_D 	db	"LD   L,RRC (IX+)",0
DDCBOp_E 	db	"RRC  (IX+)",0
DDCBOp_F 	db	"LD   A,RRC (IX+)",0
DDCBOp_10 	db	"LD   B,RL (IX+)",0
DDCBOp_11 	db	"LD   C,RL (IX+)",0
DDCBOp_12 	db	"LD   D,RL (IX+)",0
DDCBOp_13 	db	"LD   E,RL (IX+)",0
DDCBOp_14 	db	"LD   H,RL (IX+)",0
DDCBOp_15 	db	"LD   L,RL (IX+)",0
DDCBOp_16 	db	"RL   (IX+)",0
DDCBOp_17 	db	"LD   A,RL (IX+)",0
DDCBOp_18 	db	"LD   B,RR (IX+)",0
DDCBOp_19 	db	"LD   C,RR (IX+)",0
DDCBOp_1A 	db	"LD   D,RR (IX+)",0
DDCBOp_1B 	db	"LD   E,RR (IX+)",0
DDCBOp_1C 	db	"LD   H,RR (IX+)",0
DDCBOp_1D 	db	"LD   L,RR (IX+)",0
DDCBOp_1E 	db	"RR   (IX+)",0
DDCBOp_1F 	db	"LD   A,RR (IX+)",0
DDCBOp_20 	db	"LD   B,SLA (IX+)",0
DDCBOp_21 	db	"LD   C,SLA (IX+)",0
DDCBOp_22 	db	"LD   D,SLA (IX+)",0
DDCBOp_23 	db	"LD   E,SLA (IX+)",0
DDCBOp_24 	db	"LD   H,SLA (IX+)",0
DDCBOp_25 	db	"LD   L,SLA (IX+)",0
DDCBOp_26 	db	"SLA  (IX+)",0
DDCBOp_27 	db	"LD   A,SLA (IX+)",0
DDCBOp_28 	db	"LD   B,SRA (IX+)",0
DDCBOp_29 	db	"LD   C,SRA (IX+)",0
DDCBOp_2A 	db	"LD   D,SRA (IX+)",0
DDCBOp_2B 	db	"LD   E,SRA (IX+)",0
DDCBOp_2C 	db	"LD   H,SRA (IX+)",0
DDCBOp_2D 	db	"LD   L,SRA (IX+)",0
DDCBOp_2E 	db	"SRA  (IX+)",0
DDCBOp_2F 	db	"LD   A,SRA (IX+)",0
DDCBOp_30 	db	"LD   B,SLL (IX+)",0
DDCBOp_31 	db	"LD   C,SLL (IX+)",0
DDCBOp_32 	db	"LD   D,SLL (IX+)",0
DDCBOp_33 	db	"LD   E,SLL (IX+)",0
DDCBOp_34 	db	"LD   H,SLL (IX+)",0
DDCBOp_35 	db	"LD   L,SLL (IX+)",0
DDCBOp_36 	db	"SLL  (IX+)",0
DDCBOp_37 	db	"LD   A,SLL (IX+)",0
DDCBOp_38 	db	"LD   B,SRL (IX+)",0
DDCBOp_39 	db	"LD   C,SRL (IX+)",0
DDCBOp_3A 	db	"LD   D,SRL (IX+)",0
DDCBOp_3B 	db	"LD   E,SRL (IX+)",0
DDCBOp_3C 	db	"LD   H,SRL (IX+)",0
DDCBOp_3D 	db	"LD   L,SRL (IX+)",0
DDCBOp_3E 	db	"SRL  (IX+)",0
DDCBOp_3F 	db	"LD   A,SRL (IX+)",0
DDCBOp_40 	db	"BIT  0,(IX+)",0
DDCBOp_41 	db	"BIT  0,(IX+)",0
DDCBOp_42 	db	"BIT  0,(IX+)",0
DDCBOp_43 	db	"BIT  0,(IX+)",0
DDCBOp_44 	db	"BIT  0,(IX+)",0
DDCBOp_45 	db	"BIT  0,(IX+)",0
DDCBOp_46 	db	"BIT  0,(IX+)",0
DDCBOp_47 	db	"BIT  0,(IX+)",0
DDCBOp_48 	db	"BIT  1,(IX+)",0
DDCBOp_49 	db	"BIT  1,(IX+)",0
DDCBOp_4A 	db	"BIT  1,(IX+)",0
DDCBOp_4B 	db	"BIT  1,(IX+)",0
DDCBOp_4C 	db	"BIT  1,(IX+)",0
DDCBOp_4D 	db	"BIT  1,(IX+)",0
DDCBOp_4E 	db	"BIT  1,(IX+)",0
DDCBOp_4F 	db	"BIT  1,(IX+)",0
DDCBOp_50 	db	"BIT  2,(IX+)",0
DDCBOp_51 	db	"BIT  2,(IX+)",0
DDCBOp_52 	db	"BIT  2,(IX+)",0
DDCBOp_53 	db	"BIT  2,(IX+)",0
DDCBOp_54 	db	"BIT  2,(IX+)",0
DDCBOp_55 	db	"BIT  2,(IX+)",0
DDCBOp_56 	db	"BIT  2,(IX+)",0
DDCBOp_57 	db	"BIT  2,(IX+)",0
DDCBOp_58 	db	"BIT  3,(IX+)",0
DDCBOp_59 	db	"BIT  3,(IX+)",0
DDCBOp_5A 	db	"BIT  3,(IX+)",0
DDCBOp_5B 	db	"BIT  3,(IX+)",0
DDCBOp_5C 	db	"BIT  3,(IX+)",0
DDCBOp_5D 	db	"BIT  3,(IX+)",0
DDCBOp_5E 	db	"BIT  3,(IX+)",0
DDCBOp_5F 	db	"BIT  3,(IX+)",0
DDCBOp_60 	db	"BIT  4,(IX+)",0
DDCBOp_61 	db	"BIT  4,(IX+)",0
DDCBOp_62 	db	"BIT  4,(IX+)",0
DDCBOp_63 	db	"BIT  4,(IX+)",0
DDCBOp_64 	db	"BIT  4,(IX+)",0
DDCBOp_65 	db	"BIT  4,(IX+)",0
DDCBOp_66 	db	"BIT  4,(IX+)",0
DDCBOp_67 	db	"BIT  4,(IX+)",0
DDCBOp_68 	db	"BIT  5,(IX+)",0
DDCBOp_69 	db	"BIT  5,(IX+)",0
DDCBOp_6A 	db	"BIT  5,(IX+)",0
DDCBOp_6B 	db	"BIT  5,(IX+)",0
DDCBOp_6C 	db	"BIT  5,(IX+)",0
DDCBOp_6D 	db	"BIT  5,(IX+)",0
DDCBOp_6E 	db	"BIT  5,(IX+)",0
DDCBOp_6F 	db	"BIT  5,(IX+)",0
DDCBOp_70 	db	"BIT  6,(IX+)",0
DDCBOp_71 	db	"BIT  6,(IX+)",0
DDCBOp_72 	db	"BIT  6,(IX+)",0
DDCBOp_73 	db	"BIT  6,(IX+)",0
DDCBOp_74 	db	"BIT  6,(IX+)",0
DDCBOp_75 	db	"BIT  6,(IX+)",0
DDCBOp_76 	db	"BIT  6,(IX+)",0
DDCBOp_77 	db	"BIT  6,(IX+)",0
DDCBOp_78 	db	"BIT  7,(IX+)",0
DDCBOp_79 	db	"BIT  7,(IX+)",0
DDCBOp_7A 	db	"BIT  7,(IX+)",0
DDCBOp_7B 	db	"BIT  7,(IX+)",0
DDCBOp_7C 	db	"BIT  7,(IX+)",0
DDCBOp_7D 	db	"BIT  7,(IX+)",0
DDCBOp_7E 	db	"BIT  7,(IX+)",0
DDCBOp_7F 	db	"BIT  7,(IX+)",0
DDCBOp_80 	db	"LD   B,RES 0,(IX+)",0
DDCBOp_81 	db	"LD   C,RES 0,(IX+)",0
DDCBOp_82 	db	"LD   D,RES 0,(IX+)",0
DDCBOp_83 	db	"LD   E,RES 0,(IX+)",0
DDCBOp_84 	db	"LD   H,RES 0,(IX+)",0
DDCBOp_85 	db	"LD   L,RES 0,(IX+)",0
DDCBOp_86 	db	"RES  0,(IX+)",0
DDCBOp_87 	db	"LD   A,RES 0,(IX+)",0
DDCBOp_88 	db	"LD   B,RES 1,(IX+)",0
DDCBOp_89 	db	"LD   C,RES 1,(IX+)",0
DDCBOp_8A 	db	"LD   D,RES 1,(IX+)",0
DDCBOp_8B 	db	"LD   E,RES 1,(IX+)",0
DDCBOp_8C 	db	"LD   H,RES 1,(IX+)",0
DDCBOp_8D 	db	"LD   L,RES 1,(IX+)",0
DDCBOp_8E 	db	"RES  1,(IX+)",0
DDCBOp_8F 	db	"LD   A,RES 1,(IX+)",0
DDCBOp_90 	db	"LD   B,RES 2,(IX+)",0
DDCBOp_91 	db	"LD   C,RES 2,(IX+)",0
DDCBOp_92 	db	"LD   D,RES 2,(IX+)",0
DDCBOp_93 	db	"LD   E,RES 2,(IX+)",0
DDCBOp_94 	db	"LD   H,RES 2,(IX+)",0
DDCBOp_95 	db	"LD   L,RES 2,(IX+)",0
DDCBOp_96 	db	"RES  2,(IX+)",0
DDCBOp_97 	db	"LD   A,RES 2,(IX+)",0
DDCBOp_98 	db	"LD   B,RES 3,(IX+)",0
DDCBOp_99 	db	"LD   C,RES 3,(IX+)",0
DDCBOp_9A 	db	"LD   D,RES 3,(IX+)",0
DDCBOp_9B 	db	"LD   E,RES 3,(IX+)",0
DDCBOp_9C 	db	"LD   H,RES 3,(IX+)",0
DDCBOp_9D 	db	"LD   L,RES 3,(IX+)",0
DDCBOp_9E 	db	"RES  3,(IX+)",0
DDCBOp_9F 	db	"LD   A,RES 3,(IX+)",0
DDCBOp_A0 	db	"LD   B,RES 4,(IX+)",0
DDCBOp_A1 	db	"LD   C,RES 4,(IX+)",0
DDCBOp_A2 	db	"LD   D,RES 4,(IX+)",0
DDCBOp_A3 	db	"LD   E,RES 4,(IX+)",0
DDCBOp_A4 	db	"LD   H,RES 4,(IX+)",0
DDCBOp_A5 	db	"LD   L,RES 4,(IX+)",0
DDCBOp_A6 	db	"RES  4,(IX+)",0
DDCBOp_A7 	db	"LD   A,RES 4,(IX+)",0
DDCBOp_A8 	db	"LD   B,RES 5,(IX+)",0
DDCBOp_A9 	db	"LD   C,RES 5,(IX+)",0
DDCBOp_AA 	db	"LD   D,RES 5,(IX+)",0
DDCBOp_AB 	db	"LD   E,RES 5,(IX+)",0
DDCBOp_AC 	db	"LD   H,RES 5,(IX+)",0
DDCBOp_AD 	db	"LD   L,RES 5,(IX+)",0
DDCBOp_AE 	db	"RES  5,(IX+)",0
DDCBOp_AF 	db	"LD   A,RES 5,(IX+)",0
DDCBOp_B0 	db	"LD   B,RES 6,(IX+)",0
DDCBOp_B1 	db	"LD   C,RES 6,(IX+)",0
DDCBOp_B2 	db	"LD   D,RES 6,(IX+)",0
DDCBOp_B3 	db	"LD   E,RES 6,(IX+)",0
DDCBOp_B4 	db	"LD   H,RES 6,(IX+)",0
DDCBOp_B5 	db	"LD   L,RES 6,(IX+)",0
DDCBOp_B6 	db	"RES  6,(IX+)",0
DDCBOp_B7 	db	"LD   A,RES 6,(IX+)",0
DDCBOp_B8 	db	"LD   B,RES 7,(IX+)",0
DDCBOp_B9 	db	"LD   C,RES 7,(IX+)",0
DDCBOp_BA 	db	"LD   D,RES 7,(IX+)",0
DDCBOp_BB 	db	"LD   E,RES 7,(IX+)",0
DDCBOp_BC 	db	"LD   H,RES 7,(IX+)",0
DDCBOp_BD 	db	"LD   L,RES 7,(IX+)",0
DDCBOp_BE 	db	"RES  7,(IX+)",0
DDCBOp_BF 	db	"LD   A,RES 7,(IX+)",0
DDCBOp_C0 	db	"LD   B,SET 0,(IX+)",0
DDCBOp_C1 	db	"LD   C,SET 0,(IX+)",0
DDCBOp_C2 	db	"LD   D,SET 0,(IX+)",0
DDCBOp_C3 	db	"LD   E,SET 0,(IX+)",0
DDCBOp_C4 	db	"LD   H,SET 0,(IX+)",0
DDCBOp_C5 	db	"LD   L,SET 0,(IX+)",0
DDCBOp_C6 	db	"SET  0,(IX+)",0
DDCBOp_C7 	db	"LD   A,SET 0,(IX+)",0
DDCBOp_C8 	db	"LD   B,SET 1,(IX+)",0
DDCBOp_C9 	db	"LD   C,SET 1,(IX+)",0
DDCBOp_CA 	db	"LD   D,SET 1,(IX+)",0
DDCBOp_CB 	db	"LD   E,SET 1,(IX+)",0
DDCBOp_CC 	db	"LD   H,SET 1,(IX+)",0
DDCBOp_CD 	db	"LD   L,SET 1,(IX+)",0
DDCBOp_CE 	db	"SET  1,(IX+)",0
DDCBOp_CF 	db	"LD   A,SET 1,(IX+)",0
DDCBOp_D0 	db	"LD   B,SET 2,(IX+)",0
DDCBOp_D1 	db	"LD   C,SET 2,(IX+)",0
DDCBOp_D2 	db	"LD   D,SET 2,(IX+)",0
DDCBOp_D3 	db	"LD   E,SET 2,(IX+)",0
DDCBOp_D4 	db	"LD   H,SET 2,(IX+)",0
DDCBOp_D5 	db	"LD   L,SET 2,(IX+)",0
DDCBOp_D6 	db	"SET  2,(IX+)",0
DDCBOp_D7 	db	"LD   A,SET 2,(IX+)",0
DDCBOp_D8 	db	"LD   B,SET 3,(IX+)",0
DDCBOp_D9 	db	"LD   C,SET 3,(IX+)",0
DDCBOp_DA 	db	"LD   D,SET 3,(IX+)",0
DDCBOp_DB 	db	"LD   E,SET 3,(IX+)",0
DDCBOp_DC 	db	"LD   H,SET 3,(IX+)",0
DDCBOp_DD 	db	"LD   L,SET 3,(IX+)",0
DDCBOp_DE 	db	"SET  3,(IX+)",0
DDCBOp_DF 	db	"LD   A,SET 3,(IX+)",0
DDCBOp_E0 	db	"LD   B,SET 4,(IX+)",0
DDCBOp_E1 	db	"LD   C,SET 4,(IX+)",0
DDCBOp_E2 	db	"LD   D,SET 4,(IX+)",0
DDCBOp_E3 	db	"LD   E,SET 4,(IX+)",0
DDCBOp_E4 	db	"LD   H,SET 4,(IX+)",0
DDCBOp_E5 	db	"LD   L,SET 4,(IX+)",0
DDCBOp_E6 	db	"SET  4,(IX+)",0
DDCBOp_E7 	db	"LD   A,SET 4,(IX+)",0
DDCBOp_E8 	db	"LD   B,SET 5,(IX+)",0
DDCBOp_E9 	db	"LD   C,SET 5,(IX+)",0
DDCBOp_EA 	db	"LD   D,SET 5,(IX+)",0
DDCBOp_EB 	db	"LD   E,SET 5,(IX+)",0
DDCBOp_EC 	db	"LD   H,SET 5,(IX+)",0
DDCBOp_ED 	db	"LD   L,SET 5,(IX+)",0
DDCBOp_EE 	db	"SET  5,(IX+)",0
DDCBOp_EF 	db	"LD   A,SET 5,(IX+)",0
DDCBOp_F0 	db	"LD   B,SET 6,(IX+)",0
DDCBOp_F1 	db	"LD   C,SET 6,(IX+)",0
DDCBOp_F2 	db	"LD   D,SET 6,(IX+)",0
DDCBOp_F3 	db	"LD   E,SET 6,(IX+)",0
DDCBOp_F4 	db	"LD   H,SET 6,(IX+)",0
DDCBOp_F5 	db	"LD   L,SET 6,(IX+)",0
DDCBOp_F6 	db	"SET  6,(IX+)",0
DDCBOp_F7 	db	"LD   A,SET 6,(IX+)",0
DDCBOp_F8 	db	"LD   B,SET 7,(IX+)",0
DDCBOp_F9 	db	"LD   C,SET 7,(IX+)",0
DDCBOp_FA 	db	"LD   D,SET 7,(IX+)",0
DDCBOp_FB 	db	"LD   E,SET 7,(IX+)",0
DDCBOp_FC 	db	"LD   H,SET 7,(IX+)",0
DDCBOp_FD 	db	"LD   L,SET 7,(IX+)",0
DDCBOp_FE 	db	"SET  7,(IX+)",0
DDCBOp_FF 	db	"LD   A,SET 7,(IX+)",0

align 16
FDCBOpPtrs 	dd	FDCBOp_0
	dd	FDCBOp_1
	dd	FDCBOp_2
	dd	FDCBOp_3
	dd	FDCBOp_4
	dd	FDCBOp_5
	dd	FDCBOp_6
	dd	FDCBOp_7
	dd	FDCBOp_8
	dd	FDCBOp_9
	dd	FDCBOp_A
	dd	FDCBOp_B
	dd	FDCBOp_C
	dd	FDCBOp_D
	dd	FDCBOp_E
	dd	FDCBOp_F
	dd	FDCBOp_10
	dd	FDCBOp_11
	dd	FDCBOp_12
	dd	FDCBOp_13
	dd	FDCBOp_14
	dd	FDCBOp_15
	dd	FDCBOp_16
	dd	FDCBOp_17
	dd	FDCBOp_18
	dd	FDCBOp_19
	dd	FDCBOp_1A
	dd	FDCBOp_1B
	dd	FDCBOp_1C
	dd	FDCBOp_1D
	dd	FDCBOp_1E
	dd	FDCBOp_1F
	dd	FDCBOp_20
	dd	FDCBOp_21
	dd	FDCBOp_22
	dd	FDCBOp_23
	dd	FDCBOp_24
	dd	FDCBOp_25
	dd	FDCBOp_26
	dd	FDCBOp_27
	dd	FDCBOp_28
	dd	FDCBOp_29
	dd	FDCBOp_2A
	dd	FDCBOp_2B
	dd	FDCBOp_2C
	dd	FDCBOp_2D
	dd	FDCBOp_2E
	dd	FDCBOp_2F
	dd	FDCBOp_30
	dd	FDCBOp_31
	dd	FDCBOp_32
	dd	FDCBOp_33
	dd	FDCBOp_34
	dd	FDCBOp_35
	dd	FDCBOp_36
	dd	FDCBOp_37
	dd	FDCBOp_38
	dd	FDCBOp_39
	dd	FDCBOp_3A
	dd	FDCBOp_3B
	dd	FDCBOp_3C
	dd	FDCBOp_3D
	dd	FDCBOp_3E
	dd	FDCBOp_3F
	dd	FDCBOp_40
	dd	FDCBOp_41
	dd	FDCBOp_42
	dd	FDCBOp_43
	dd	FDCBOp_44
	dd	FDCBOp_45
	dd	FDCBOp_46
	dd	FDCBOp_47
	dd	FDCBOp_48
	dd	FDCBOp_49
	dd	FDCBOp_4A
	dd	FDCBOp_4B
	dd	FDCBOp_4C
	dd	FDCBOp_4D
	dd	FDCBOp_4E
	dd	FDCBOp_4F
	dd	FDCBOp_50
	dd	FDCBOp_51
	dd	FDCBOp_52
	dd	FDCBOp_53
	dd	FDCBOp_54
	dd	FDCBOp_55
	dd	FDCBOp_56
	dd	FDCBOp_57
	dd	FDCBOp_58
	dd	FDCBOp_59
	dd	FDCBOp_5A
	dd	FDCBOp_5B
	dd	FDCBOp_5C
	dd	FDCBOp_5D
	dd	FDCBOp_5E
	dd	FDCBOp_5F
	dd	FDCBOp_60
	dd	FDCBOp_61
	dd	FDCBOp_62
	dd	FDCBOp_63
	dd	FDCBOp_64
	dd	FDCBOp_65
	dd	FDCBOp_66
	dd	FDCBOp_67
	dd	FDCBOp_68
	dd	FDCBOp_69
	dd	FDCBOp_6A
	dd	FDCBOp_6B
	dd	FDCBOp_6C
	dd	FDCBOp_6D
	dd	FDCBOp_6E
	dd	FDCBOp_6F
	dd	FDCBOp_70
	dd	FDCBOp_71
	dd	FDCBOp_72
	dd	FDCBOp_73
	dd	FDCBOp_74
	dd	FDCBOp_75
	dd	FDCBOp_76
	dd	FDCBOp_77
	dd	FDCBOp_78
	dd	FDCBOp_79
	dd	FDCBOp_7A
	dd	FDCBOp_7B
	dd	FDCBOp_7C
	dd	FDCBOp_7D
	dd	FDCBOp_7E
	dd	FDCBOp_7F
	dd	FDCBOp_80
	dd	FDCBOp_81
	dd	FDCBOp_82
	dd	FDCBOp_83
	dd	FDCBOp_84
	dd	FDCBOp_85
	dd	FDCBOp_86
	dd	FDCBOp_87
	dd	FDCBOp_88
	dd	FDCBOp_89
	dd	FDCBOp_8A
	dd	FDCBOp_8B
	dd	FDCBOp_8C
	dd	FDCBOp_8D
	dd	FDCBOp_8E
	dd	FDCBOp_8F
	dd	FDCBOp_90
	dd	FDCBOp_91
	dd	FDCBOp_92
	dd	FDCBOp_93
	dd	FDCBOp_94
	dd	FDCBOp_95
	dd	FDCBOp_96
	dd	FDCBOp_97
	dd	FDCBOp_98
	dd	FDCBOp_99
	dd	FDCBOp_9A
	dd	FDCBOp_9B
	dd	FDCBOp_9C
	dd	FDCBOp_9D
	dd	FDCBOp_9E
	dd	FDCBOp_9F
	dd	FDCBOp_A0
	dd	FDCBOp_A1
	dd	FDCBOp_A2
	dd	FDCBOp_A3
	dd	FDCBOp_A4
	dd	FDCBOp_A5
	dd	FDCBOp_A6
	dd	FDCBOp_A7
	dd	FDCBOp_A8
	dd	FDCBOp_A9
	dd	FDCBOp_AA
	dd	FDCBOp_AB
	dd	FDCBOp_AC
	dd	FDCBOp_AD
	dd	FDCBOp_AE
	dd	FDCBOp_AF
	dd	FDCBOp_B0
	dd	FDCBOp_B1
	dd	FDCBOp_B2
	dd	FDCBOp_B3
	dd	FDCBOp_B4
	dd	FDCBOp_B5
	dd	FDCBOp_B6
	dd	FDCBOp_B7
	dd	FDCBOp_B8
	dd	FDCBOp_B9
	dd	FDCBOp_BA
	dd	FDCBOp_BB
	dd	FDCBOp_BC
	dd	FDCBOp_BD
	dd	FDCBOp_BE
	dd	FDCBOp_BF
	dd	FDCBOp_C0
	dd	FDCBOp_C1
	dd	FDCBOp_C2
	dd	FDCBOp_C3
	dd	FDCBOp_C4
	dd	FDCBOp_C5
	dd	FDCBOp_C6
	dd	FDCBOp_C7
	dd	FDCBOp_C8
	dd	FDCBOp_C9
	dd	FDCBOp_CA
	dd	FDCBOp_CB
	dd	FDCBOp_CC
	dd	FDCBOp_CD
	dd	FDCBOp_CE
	dd	FDCBOp_CF
	dd	FDCBOp_D0
	dd	FDCBOp_D1
	dd	FDCBOp_D2
	dd	FDCBOp_D3
	dd	FDCBOp_D4
	dd	FDCBOp_D5
	dd	FDCBOp_D6
	dd	FDCBOp_D7
	dd	FDCBOp_D8
	dd	FDCBOp_D9
	dd	FDCBOp_DA
	dd	FDCBOp_DB
	dd	FDCBOp_DC
	dd	FDCBOp_DD
	dd	FDCBOp_DE
	dd	FDCBOp_DF
	dd	FDCBOp_E0
	dd	FDCBOp_E1
	dd	FDCBOp_E2
	dd	FDCBOp_E3
	dd	FDCBOp_E4
	dd	FDCBOp_E5
	dd	FDCBOp_E6
	dd	FDCBOp_E7
	dd	FDCBOp_E8
	dd	FDCBOp_E9
	dd	FDCBOp_EA
	dd	FDCBOp_EB
	dd	FDCBOp_EC
	dd	FDCBOp_ED
	dd	FDCBOp_EE
	dd	FDCBOp_EF
	dd	FDCBOp_F0
	dd	FDCBOp_F1
	dd	FDCBOp_F2
	dd	FDCBOp_F3
	dd	FDCBOp_F4
	dd	FDCBOp_F5
	dd	FDCBOp_F6
	dd	FDCBOp_F7
	dd	FDCBOp_F8
	dd	FDCBOp_F9
	dd	FDCBOp_FA
	dd	FDCBOp_FB
	dd	FDCBOp_FC
	dd	FDCBOp_FD
	dd	FDCBOp_FE
	dd	FDCBOp_FF
FDCBOp_0 	db	"LD   B,RLC (IY+)",0
FDCBOp_1 	db	"LD   C,RLC (IY+)",0
FDCBOp_2 	db	"LD   D,RLC (IY+)",0
FDCBOp_3 	db	"LD   E,RLC (IY+)",0
FDCBOp_4 	db	"LD   H,RLC (IY+)",0
FDCBOp_5 	db	"LD   L,RLC (IY+)",0
FDCBOp_6 	db	"RLC  (IY+)",0
FDCBOp_7 	db	"LD   A,RLC (IY+)",0
FDCBOp_8 	db	"LD   B,RRC (IY+)",0
FDCBOp_9 	db	"LD   C,RRC (IY+)",0
FDCBOp_A 	db	"LD   D,RRC (IY+)",0
FDCBOp_B 	db	"LD   E,RRC (IY+)",0
FDCBOp_C 	db	"LD   H,RRC (IY+)",0
FDCBOp_D 	db	"LD   L,RRC (IY+)",0
FDCBOp_E 	db	"RRC  (IY+)",0
FDCBOp_F 	db	"LD   A,RRC (IY+)",0
FDCBOp_10 	db	"LD   B,RL (IY+)",0
FDCBOp_11 	db	"LD   C,RL (IY+)",0
FDCBOp_12 	db	"LD   D,RL (IY+)",0
FDCBOp_13 	db	"LD   E,RL (IY+)",0
FDCBOp_14 	db	"LD   H,RL (IY+)",0
FDCBOp_15 	db	"LD   L,RL (IY+)",0
FDCBOp_16 	db	"RL   (IY+)",0
FDCBOp_17 	db	"LD   A,RL (IY+)",0
FDCBOp_18 	db	"LD   B,RR (IY+)",0
FDCBOp_19 	db	"LD   C,RR (IY+)",0
FDCBOp_1A 	db	"LD   D,RR (IY+)",0
FDCBOp_1B 	db	"LD   E,RR (IY+)",0
FDCBOp_1C 	db	"LD   H,RR (IY+)",0
FDCBOp_1D 	db	"LD   L,RR (IY+)",0
FDCBOp_1E 	db	"RR   (IY+)",0
FDCBOp_1F 	db	"LD   A,RR (IY+)",0
FDCBOp_20 	db	"LD   B,SLA (IY+)",0
FDCBOp_21 	db	"LD   C,SLA (IY+)",0
FDCBOp_22 	db	"LD   D,SLA (IY+)",0
FDCBOp_23 	db	"LD   E,SLA (IY+)",0
FDCBOp_24 	db	"LD   H,SLA (IY+)",0
FDCBOp_25 	db	"LD   L,SLA (IY+)",0
FDCBOp_26 	db	"SLA  (IY+)",0
FDCBOp_27 	db	"LD   A,SLA (IY+)",0
FDCBOp_28 	db	"LD   B,SRA (IY+)",0
FDCBOp_29 	db	"LD   C,SRA (IY+)",0
FDCBOp_2A 	db	"LD   D,SRA (IY+)",0
FDCBOp_2B 	db	"LD   E,SRA (IY+)",0
FDCBOp_2C 	db	"LD   H,SRA (IY+)",0
FDCBOp_2D 	db	"LD   L,SRA (IY+)",0
FDCBOp_2E 	db	"SRA  (IY+)",0
FDCBOp_2F 	db	"LD   A,SRA (IY+)",0
FDCBOp_30 	db	"LD   B,SLL (IY+)",0
FDCBOp_31 	db	"LD   C,SLL (IY+)",0
FDCBOp_32 	db	"LD   D,SLL (IY+)",0
FDCBOp_33 	db	"LD   E,SLL (IY+)",0
FDCBOp_34 	db	"LD   H,SLL (IY+)",0
FDCBOp_35 	db	"LD   L,SLL (IY+)",0
FDCBOp_36 	db	"SLL  (IY+)",0
FDCBOp_37 	db	"LD   A,SLL (IY+)",0
FDCBOp_38 	db	"LD   B,SRL (IY+)",0
FDCBOp_39 	db	"LD   C,SRL (IY+)",0
FDCBOp_3A 	db	"LD   D,SRL (IY+)",0
FDCBOp_3B 	db	"LD   E,SRL (IY+)",0
FDCBOp_3C 	db	"LD   H,SRL (IY+)",0
FDCBOp_3D 	db	"LD   L,SRL (IY+)",0
FDCBOp_3E 	db	"SRL  (IY+)",0
FDCBOp_3F 	db	"LD   A,SRL (IY+)",0
FDCBOp_40 	db	"BIT  0,(IY+)",0
FDCBOp_41 	db	"BIT  0,(IY+)",0
FDCBOp_42 	db	"BIT  0,(IY+)",0
FDCBOp_43 	db	"BIT  0,(IY+)",0
FDCBOp_44 	db	"BIT  0,(IY+)",0
FDCBOp_45 	db	"BIT  0,(IY+)",0
FDCBOp_46 	db	"BIT  0,(IY+)",0
FDCBOp_47 	db	"BIT  0,(IY+)",0
FDCBOp_48 	db	"BIT  1,(IY+)",0
FDCBOp_49 	db	"BIT  1,(IY+)",0
FDCBOp_4A 	db	"BIT  1,(IY+)",0
FDCBOp_4B 	db	"BIT  1,(IY+)",0
FDCBOp_4C 	db	"BIT  1,(IY+)",0
FDCBOp_4D 	db	"BIT  1,(IY+)",0
FDCBOp_4E 	db	"BIT  1,(IY+)",0
FDCBOp_4F 	db	"BIT  1,(IY+)",0
FDCBOp_50 	db	"BIT  2,(IY+)",0
FDCBOp_51 	db	"BIT  2,(IY+)",0
FDCBOp_52 	db	"BIT  2,(IY+)",0
FDCBOp_53 	db	"BIT  2,(IY+)",0
FDCBOp_54 	db	"BIT  2,(IY+)",0
FDCBOp_55 	db	"BIT  2,(IY+)",0
FDCBOp_56 	db	"BIT  2,(IY+)",0
FDCBOp_57 	db	"BIT  2,(IY+)",0
FDCBOp_58 	db	"BIT  3,(IY+)",0
FDCBOp_59 	db	"BIT  3,(IY+)",0
FDCBOp_5A 	db	"BIT  3,(IY+)",0
FDCBOp_5B 	db	"BIT  3,(IY+)",0
FDCBOp_5C 	db	"BIT  3,(IY+)",0
FDCBOp_5D 	db	"BIT  3,(IY+)",0
FDCBOp_5E 	db	"BIT  3,(IY+)",0
FDCBOp_5F 	db	"BIT  3,(IY+)",0
FDCBOp_60 	db	"BIT  4,(IY+)",0
FDCBOp_61 	db	"BIT  4,(IY+)",0
FDCBOp_62 	db	"BIT  4,(IY+)",0
FDCBOp_63 	db	"BIT  4,(IY+)",0
FDCBOp_64 	db	"BIT  4,(IY+)",0
FDCBOp_65 	db	"BIT  4,(IY+)",0
FDCBOp_66 	db	"BIT  4,(IY+)",0
FDCBOp_67 	db	"BIT  4,(IY+)",0
FDCBOp_68 	db	"BIT  5,(IY+)",0
FDCBOp_69 	db	"BIT  5,(IY+)",0
FDCBOp_6A 	db	"BIT  5,(IY+)",0
FDCBOp_6B 	db	"BIT  5,(IY+)",0
FDCBOp_6C 	db	"BIT  5,(IY+)",0
FDCBOp_6D 	db	"BIT  5,(IY+)",0
FDCBOp_6E 	db	"BIT  5,(IY+)",0
FDCBOp_6F 	db	"BIT  5,(IY+)",0
FDCBOp_70 	db	"BIT  6,(IY+)",0
FDCBOp_71 	db	"BIT  6,(IY+)",0
FDCBOp_72 	db	"BIT  6,(IY+)",0
FDCBOp_73 	db	"BIT  6,(IY+)",0
FDCBOp_74 	db	"BIT  6,(IY+)",0
FDCBOp_75 	db	"BIT  6,(IY+)",0
FDCBOp_76 	db	"BIT  6,(IY+)",0
FDCBOp_77 	db	"BIT  6,(IY+)",0
FDCBOp_78 	db	"BIT  7,(IY+)",0
FDCBOp_79 	db	"BIT  7,(IY+)",0
FDCBOp_7A 	db	"BIT  7,(IY+)",0
FDCBOp_7B 	db	"BIT  7,(IY+)",0
FDCBOp_7C 	db	"BIT  7,(IY+)",0
FDCBOp_7D 	db	"BIT  7,(IY+)",0
FDCBOp_7E 	db	"BIT  7,(IY+)",0
FDCBOp_7F 	db	"BIT  7,(IY+)",0
FDCBOp_80 	db	"LD   B,RES 0,(IY+)",0
FDCBOp_81 	db	"LD   C,RES 0,(IY+)",0
FDCBOp_82 	db	"LD   D,RES 0,(IY+)",0
FDCBOp_83 	db	"LD   E,RES 0,(IY+)",0
FDCBOp_84 	db	"LD   H,RES 0,(IY+)",0
FDCBOp_85 	db	"LD   L,RES 0,(IY+)",0
FDCBOp_86 	db	"RES  0,(IY+)",0
FDCBOp_87 	db	"LD   A,RES 0,(IY+)",0
FDCBOp_88 	db	"LD   B,RES 1,(IY+)",0
FDCBOp_89 	db	"LD   C,RES 1,(IY+)",0
FDCBOp_8A 	db	"LD   D,RES 1,(IY+)",0
FDCBOp_8B 	db	"LD   E,RES 1,(IY+)",0
FDCBOp_8C 	db	"LD   H,RES 1,(IY+)",0
FDCBOp_8D 	db	"LD   L,RES 1,(IY+)",0
FDCBOp_8E 	db	"RES  1,(IY+)",0
FDCBOp_8F 	db	"LD   A,RES 1,(IY+)",0
FDCBOp_90 	db	"LD   B,RES 2,(IY+)",0
FDCBOp_91 	db	"LD   C,RES 2,(IY+)",0
FDCBOp_92 	db	"LD   D,RES 2,(IY+)",0
FDCBOp_93 	db	"LD   E,RES 2,(IY+)",0
FDCBOp_94 	db	"LD   H,RES 2,(IY+)",0
FDCBOp_95 	db	"LD   L,RES 2,(IY+)",0
FDCBOp_96 	db	"RES  2,(IY+)",0
FDCBOp_97 	db	"LD   A,RES 2,(IY+)",0
FDCBOp_98 	db	"LD   B,RES 3,(IY+)",0
FDCBOp_99 	db	"LD   C,RES 3,(IY+)",0
FDCBOp_9A 	db	"LD   D,RES 3,(IY+)",0
FDCBOp_9B 	db	"LD   E,RES 3,(IY+)",0
FDCBOp_9C 	db	"LD   H,RES 3,(IY+)",0
FDCBOp_9D 	db	"LD   L,RES 3,(IY+)",0
FDCBOp_9E 	db	"RES  3,(IY+)",0
FDCBOp_9F 	db	"LD   A,RES 3,(IY+)",0
FDCBOp_A0 	db	"LD   B,RES 4,(IY+)",0
FDCBOp_A1 	db	"LD   C,RES 4,(IY+)",0
FDCBOp_A2 	db	"LD   D,RES 4,(IY+)",0
FDCBOp_A3 	db	"LD   E,RES 4,(IY+)",0
FDCBOp_A4 	db	"LD   H,RES 4,(IY+)",0
FDCBOp_A5 	db	"LD   L,RES 4,(IY+)",0
FDCBOp_A6 	db	"RES  4,(IY+)",0
FDCBOp_A7 	db	"LD   A,RES 4,(IY+)",0
FDCBOp_A8 	db	"LD   B,RES 5,(IY+)",0
FDCBOp_A9 	db	"LD   C,RES 5,(IY+)",0
FDCBOp_AA 	db	"LD   D,RES 5,(IY+)",0
FDCBOp_AB 	db	"LD   E,RES 5,(IY+)",0
FDCBOp_AC 	db	"LD   H,RES 5,(IY+)",0
FDCBOp_AD 	db	"LD   L,RES 5,(IY+)",0
FDCBOp_AE 	db	"RES  5,(IY+)",0
FDCBOp_AF 	db	"LD   A,RES 5,(IY+)",0
FDCBOp_B0 	db	"LD   B,RES 6,(IY+)",0
FDCBOp_B1 	db	"LD   C,RES 6,(IY+)",0
FDCBOp_B2 	db	"LD   D,RES 6,(IY+)",0
FDCBOp_B3 	db	"LD   E,RES 6,(IY+)",0
FDCBOp_B4 	db	"LD   H,RES 6,(IY+)",0
FDCBOp_B5 	db	"LD   L,RES 6,(IY+)",0
FDCBOp_B6 	db	"RES  6,(IY+)",0
FDCBOp_B7 	db	"LD   A,RES 6,(IY+)",0
FDCBOp_B8 	db	"LD   B,RES 7,(IY+)",0
FDCBOp_B9 	db	"LD   C,RES 7,(IY+)",0
FDCBOp_BA 	db	"LD   D,RES 7,(IY+)",0
FDCBOp_BB 	db	"LD   E,RES 7,(IY+)",0
FDCBOp_BC 	db	"LD   H,RES 7,(IY+)",0
FDCBOp_BD 	db	"LD   L,RES 7,(IY+)",0
FDCBOp_BE 	db	"RES  7,(IY+)",0
FDCBOp_BF 	db	"LD   A,RES 7,(IY+)",0
FDCBOp_C0 	db	"LD   B,SET 0,(IY+)",0
FDCBOp_C1 	db	"LD   C,SET 0,(IY+)",0
FDCBOp_C2 	db	"LD   D,SET 0,(IY+)",0
FDCBOp_C3 	db	"LD   E,SET 0,(IY+)",0
FDCBOp_C4 	db	"LD   H,SET 0,(IY+)",0
FDCBOp_C5 	db	"LD   L,SET 0,(IY+)",0
FDCBOp_C6 	db	"SET  0,(IY+)",0
FDCBOp_C7 	db	"LD   A,SET 0,(IY+)",0
FDCBOp_C8 	db	"LD   B,SET 1,(IY+)",0
FDCBOp_C9 	db	"LD   C,SET 1,(IY+)",0
FDCBOp_CA 	db	"LD   D,SET 1,(IY+)",0
FDCBOp_CB 	db	"LD   E,SET 1,(IY+)",0
FDCBOp_CC 	db	"LD   H,SET 1,(IY+)",0
FDCBOp_CD 	db	"LD   L,SET 1,(IY+)",0
FDCBOp_CE 	db	"SET  1,(IY+)",0
FDCBOp_CF 	db	"LD   A,SET 1,(IY+)",0
FDCBOp_D0 	db	"LD   B,SET 2,(IY+)",0
FDCBOp_D1 	db	"LD   C,SET 2,(IY+)",0
FDCBOp_D2 	db	"LD   D,SET 2,(IY+)",0
FDCBOp_D3 	db	"LD   E,SET 2,(IY+)",0
FDCBOp_D4 	db	"LD   H,SET 2,(IY+)",0
FDCBOp_D5 	db	"LD   L,SET 2,(IY+)",0
FDCBOp_D6 	db	"SET  2,(IY+)",0
FDCBOp_D7 	db	"LD   A,SET 2,(IY+)",0
FDCBOp_D8 	db	"LD   B,SET 3,(IY+)",0
FDCBOp_D9 	db	"LD   C,SET 3,(IY+)",0
FDCBOp_DA 	db	"LD   D,SET 3,(IY+)",0
FDCBOp_DB 	db	"LD   E,SET 3,(IY+)",0
FDCBOp_DC 	db	"LD   H,SET 3,(IY+)",0
FDCBOp_DD 	db	"LD   L,SET 3,(IY+)",0
FDCBOp_DE 	db	"SET  3,(IY+)",0
FDCBOp_DF 	db	"LD   A,SET 3,(IY+)",0
FDCBOp_E0 	db	"LD   B,SET 4,(IY+)",0
FDCBOp_E1 	db	"LD   C,SET 4,(IY+)",0
FDCBOp_E2 	db	"LD   D,SET 4,(IY+)",0
FDCBOp_E3 	db	"LD   E,SET 4,(IY+)",0
FDCBOp_E4 	db	"LD   H,SET 4,(IY+)",0
FDCBOp_E5 	db	"LD   L,SET 4,(IY+)",0
FDCBOp_E6 	db	"SET  4,(IY+)",0
FDCBOp_E7 	db	"LD   A,SET 4,(IY+)",0
FDCBOp_E8 	db	"LD   B,SET 5,(IY+)",0
FDCBOp_E9 	db	"LD   C,SET 5,(IY+)",0
FDCBOp_EA 	db	"LD   D,SET 5,(IY+)",0
FDCBOp_EB 	db	"LD   E,SET 5,(IY+)",0
FDCBOp_EC 	db	"LD   H,SET 5,(IY+)",0
FDCBOp_ED 	db	"LD   L,SET 5,(IY+)",0
FDCBOp_EE 	db	"SET  5,(IY+)",0
FDCBOp_EF 	db	"LD   A,SET 5,(IY+)",0
FDCBOp_F0 	db	"LD   B,SET 6,(IY+)",0
FDCBOp_F1 	db	"LD   C,SET 6,(IY+)",0
FDCBOp_F2 	db	"LD   D,SET 6,(IY+)",0
FDCBOp_F3 	db	"LD   E,SET 6,(IY+)",0
FDCBOp_F4 	db	"LD   H,SET 6,(IY+)",0
FDCBOp_F5 	db	"LD   L,SET 6,(IY+)",0
FDCBOp_F6 	db	"SET  6,(IY+)",0
FDCBOp_F7 	db	"LD   A,SET 6,(IY+)",0
FDCBOp_F8 	db	"LD   B,SET 7,(IY+)",0
FDCBOp_F9 	db	"LD   C,SET 7,(IY+)",0
FDCBOp_FA 	db	"LD   D,SET 7,(IY+)",0
FDCBOp_FB 	db	"LD   E,SET 7,(IY+)",0
FDCBOp_FC 	db	"LD   H,SET 7,(IY+)",0
FDCBOp_FD 	db	"LD   L,SET 7,(IY+)",0
FDCBOp_FE 	db	"SET  7,(IY+)",0
FDCBOp_FF 	db	"LD   A,SET 7,(IY+)",0
.code

