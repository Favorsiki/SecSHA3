def ReOrderChiSquence():
    InitialSquence = []
    AnswerSquence = []
    for i in range(1600) :
        InitialSquence.append(i)
    for z in range(64):
        for y in range(5):
            for x in range(5):
                indx = (5 * y + x) * 64 + z
                AnswerSquence.append(indx)
    file = open("keccak_ReOrderChiSquence.v", "w")
    # ReOrderChiSquence
    file.write("module ReOrderChiSquence(\n")
    file.write("    input [1599:0] orgin,    \n")
    file.write("    input [1599:0] reorder   \n")
    file.write(");\n")
    for i in range(0,1600,5) :
        file.write("    assign reorder[%d:%d] \t= {orgin[%d], orgin[%d], orgin[%d], orgin[%d], orgin[%d]};\n"
                   %(i+4, i, AnswerSquence[i+4], AnswerSquence[i+3], AnswerSquence[i+2], AnswerSquence[i+1], AnswerSquence[i]))
    file.write("endmodule\n\n\n")

    #InvReOrderChiSquence
    file.write("module InvReOrderChiSquence(\n")
    file.write("    input [1599:0] reorder,    \n")
    file.write("    input [1599:0] orgin     \n")
    file.write(");\n")
    for i in range(0,1600,5) :
        file.write("    assign {orgin[%d], orgin[%d], orgin[%d], orgin[%d], orgin[%d]} \t= reorder[%d:%d];\n"
                   %(AnswerSquence[i+4], AnswerSquence[i+3], AnswerSquence[i+2], AnswerSquence[i+1], AnswerSquence[i], i+4, i))
        #file.write("    assign y[%d] = x[%d];\n"%(AnswerSquence[i], i))
    file.write("endmodule\n")

    file.close()

ReOrderChiSquence()