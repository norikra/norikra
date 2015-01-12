module Norikra
  class Query
    ### SELECT max(size) AS maxsize, fraud.aaa, bbb
    ### FROM FraudWarningEvent.win:keepall() AS fraud,
    ###      PINChangeEvent(size > 10).win:time(20 sec)
    ### WHERE fraud.accountNumber.substr(0,8) = substr(PINChangeEvent.accountNumber, 0, 8)
    ###   AND cast(PINChangeEvent.size,double) > 10.5

    # ["startEPLExpressionRule",
    #   ["eplExpression",
    #     ["selectExpr",
    #       "SELECT",
    #       ["selectClause",
    #         ["selectionList",
    #           ["selectionListElement",
    #             ["selectionListElementExpr",
    #               ["expression",
    #                 ["caseExpression",
    #                   ["evalOrExpression",
    #                     ["evalAndExpression",
    #                       ["bitWiseExpression",
    #                         ["negatedExpression",
    #                           ["evalEqualsExpression",
    #                             ["evalRelationalExpression",
    #                               ["concatenationExpr",
    #                                 ["additiveExpression",
    #                                   ["multiplyExpression",
    #                                     ["unaryExpression",
    #                                       ["eventPropertyOrLibFunction",
    #                                         ["libFunction",
    #                                           ["libFunctionWithClass",
    #                                             ["funcIdentTop", "max"],
    #                                             "(",
    #                                             ["libFunctionArgs",
    #                                               ["libFunctionArgItem",
    #                                                 ["expressionWithTime",
    #                                                   ["expressionQualifyable",
    #                                                     ["expression",
    #                                                       ["caseExpression",
    #                                                         ["evalOrExpression",
    #                                                           ["evalAndExpression",
    #                                                             ["bitWiseExpression",
    #                                                               ["negatedExpression",
    #                                                                 ["evalEqualsExpression",
    #                                                                   ["evalRelationalExpression",
    #                                                                     ["concatenationExpr",
    #                                                                       ["additiveExpression",
    #                                                                         ["multiplyExpression",
    #                                                                           ["unaryExpression",
    #                                                                             ["eventPropertyOrLibFunction",
    #                                                                               ["eventProperty",
    #                                                                                 ["eventPropertyAtomic",
    #                                                                                   ["eventPropertyIdent",
    #                                                                                     ["keywordAllowedIdent",
    #                                                                                       "size"]]]]]]]]]]]]]]]]]]]]],
    #                                             ")"]]]]]]]]]]]]]]],
    #               "AS",
    #               ["keywordAllowedIdent", "maxsize"]]],
    #           ",",
    #           ["selectionListElement",
    #             ["selectionListElementExpr",
    #               ["expression",
    #                 ["caseExpression",
    #                   ["evalOrExpression",
    #                     ["evalAndExpression",
    #                       ["bitWiseExpression",
    #                         ["negatedExpression",
    #                           ["evalEqualsExpression",
    #                             ["evalRelationalExpression",
    #                               ["concatenationExpr",
    #                                 ["additiveExpression",
    #                                   ["multiplyExpression",
    #                                     ["unaryExpression",
    #                                       ["eventPropertyOrLibFunction",
    #                                         ["eventProperty",
    #                                           ["eventPropertyAtomic",
    #                                             ["eventPropertyIdent",
    #                                               ["keywordAllowedIdent", "fraud"]]],
    #                                           ".",
    #                                           ["eventPropertyAtomic",
    #                                             ["eventPropertyIdent",
    #                                               ["keywordAllowedIdent", "aaa"]]]]]]]]]]]]]]]]]]],
    #           ",",
    #           ["selectionListElement",
    #             ["selectionListElementExpr",
    #               ["expression",
    #                 ["caseExpression",
    #                   ["evalOrExpression",
    #                     ["evalAndExpression",
    #                       ["bitWiseExpression",
    #                         ["negatedExpression",
    #                           ["evalEqualsExpression",
    #                             ["evalRelationalExpression",
    #                               ["concatenationExpr",
    #                                 ["additiveExpression",
    #                                   ["multiplyExpression",
    #                                     ["unaryExpression",
    #                                       ["eventPropertyOrLibFunction",
    #                                         ["eventProperty",
    #                                           ["eventPropertyAtomic",
    #                                             ["eventPropertyIdent",
    #                                               ["keywordAllowedIdent", "bbb"]]]]]]]]]]]]]]]]]]]]],
    #       "FROM",
    #       ["fromClause",
    #         ["streamExpression",
    #           ["eventFilterExpression",
    #             ["classIdentifier", ["escapableStr", "FraudWarningEvent"]]],
    #           ".",
    #           ["viewExpression", "win", ":", "keepall", "(", ")"],
    #           "AS",
    #           "fraud"],
    #         ["regularJoin",
    #           ",",
    #           ["streamExpression",
    #             ["eventFilterExpression",
    #               ["classIdentifier", ["escapableStr", "PINChangeEvent"]],
    #               "(",
    #               ["expressionList",
    #                 ["expression",
    #                   ["caseExpression",
    #                     ["evalOrExpression",
    #                       ["evalAndExpression",
    #                         ["bitWiseExpression",
    #                           ["negatedExpression",
    #                             ["evalEqualsExpression",
    #                               ["evalRelationalExpression",
    #                                 ["concatenationExpr",
    #                                   ["additiveExpression",
    #                                     ["multiplyExpression",
    #                                       ["unaryExpression",
    #                                         ["eventPropertyOrLibFunction",
    #                                           ["eventProperty",
    #                                             ["eventPropertyAtomic",
    #                                               ["eventPropertyIdent",
    #                                                 ["keywordAllowedIdent", "size"]]]]]]]]],
    #                                 ">",
    #                                 ["concatenationExpr",
    #                                   ["additiveExpression",
    #                                     ["multiplyExpression",
    #                                       ["unaryExpression",
    #                                         ["constant",
    #                                           ["numberconstant", ["number", "10"]]]]]]]]]]]]]]]],
    #               ")"],
    #             ".",
    #             ["viewExpression",
    #               "win",
    #               ":",
    #               "time",
    #               "(",
    #               ["expressionWithTimeList",
    #                 ["expressionWithTimeInclLast",
    #                   ["expressionWithTime",
    #                     ["timePeriod",
    #                       ["secondPart", ["numberconstant", ["number", "20"]], "sec"]]]]],
    #               ")"]]]],
    #       "WHERE",
    #       ["whereClause",
    #         ["evalOrExpression",
    #           ["evalAndExpression",
    #             ["bitWiseExpression",
    #               ["negatedExpression",
    #                 ["evalEqualsExpression",
    #                   ["evalRelationalExpression",
    #                     ["concatenationExpr",
    #                       ["additiveExpression",
    #                         ["multiplyExpression",
    #                           ["unaryExpression",
    #                             ["eventPropertyOrLibFunction",
    #                               ["libFunction",
    #                                 ["libFunctionWithClass",
    #                                   ["classIdentifier",
    #                                     ["escapableStr", "fraud"],
    #                                     ".",
    #                                     ["escapableStr", "accountNumber"]],
    #                                   ".",
    #                                   ["funcIdentTop", ["escapableIdent", "substr"]],
    #                                   "(",
    #                                   ["libFunctionArgs",
    #                                     ["libFunctionArgItem",
    #                                       ["expressionWithTime",
    #                                         ["expressionQualifyable",
    #                                           ["expression",
    #                                             ["caseExpression",
    #                                               ["evalOrExpression",
    #                                                 ["evalAndExpression",
    #                                                   ["bitWiseExpression",
    #                                                     ["negatedExpression",
    #                                                       ["evalEqualsExpression",
    #                                                         ["evalRelationalExpression",
    #                                                           ["concatenationExpr",
    #                                                             ["additiveExpression",
    #                                                               ["multiplyExpression",
    #                                                                 ["unaryExpression",
    #                                                                   ["constant",
    #                                                                     ["numberconstant",
    #                                                                       ["number", "0"]]]]]]]]]]]]]]]]]],
    #                                     ",",
    #                                     ["libFunctionArgItem",
    #                                       ["expressionWithTime",
    #                                         ["expressionQualifyable",
    #                                           ["expression",
    #                                             ["caseExpression",
    #                                               ["evalOrExpression",
    #                                                 ["evalAndExpression",
    #                                                   ["bitWiseExpression",
    #                                                     ["negatedExpression",
    #                                                       ["evalEqualsExpression",
    #                                                         ["evalRelationalExpression",
    #                                                           ["concatenationExpr",
    #                                                             ["additiveExpression",
    #                                                               ["multiplyExpression",
    #                                                                 ["unaryExpression",
    #                                                                   ["constant",
    #                                                                     ["numberconstant",
    #                                                                       ["number", "8"]]]]]]]]]]]]]]]]]]],
    #                                   ")"]]]]]]]],
    #                   "=",
    #                   ["evalRelationalExpression",
    #                     ["concatenationExpr",
    #                       ["additiveExpression",
    #                         ["multiplyExpression",
    #                           ["unaryExpression",
    #                             ["eventPropertyOrLibFunction",
    #                               ["libFunction",
    #                                 ["libFunctionWithClass",
    #                                   ["funcIdentTop", ["escapableIdent", "substr"]],
    #                                   "(",
    #                                   ["libFunctionArgs",
    #                                     ["libFunctionArgItem",
    #                                       ["expressionWithTime",
    #                                         ["expressionQualifyable",
    #                                           ["expression",
    #                                             ["caseExpression",
    #                                               ["evalOrExpression",
    #                                                 ["evalAndExpression",
    #                                                   ["bitWiseExpression",
    #                                                     ["negatedExpression",
    #                                                       ["evalEqualsExpression",
    #                                                         ["evalRelationalExpression",
    #                                                           ["concatenationExpr",
    #                                                             ["additiveExpression",
    #                                                               ["multiplyExpression",
    #                                                                 ["unaryExpression",
    #                                                                   ["eventPropertyOrLibFunction",
    #                                                                     ["eventProperty",
    #                                                                       ["eventPropertyAtomic",
    #                                                                         ["eventPropertyIdent",
    #                                                                           ["keywordAllowedIdent",
    #                                                                             "PINChangeEvent"]]],
    #                                                                       ".",
    #                                                                       ["eventPropertyAtomic",
    #                                                                         ["eventPropertyIdent",
    #                                                                           ["keywordAllowedIdent",
    #                                                                             "accountNumber"]]]]]]]]]]]]]]]]]]]],
    #                                     ",",
    #                                     ["libFunctionArgItem",
    #                                       ["expressionWithTime",
    #                                         ["expressionQualifyable",
    #                                           ["expression",
    #                                             ["caseExpression",
    #                                               ["evalOrExpression",
    #                                                 ["evalAndExpression",
    #                                                   ["bitWiseExpression",
    #                                                     ["negatedExpression",
    #                                                       ["evalEqualsExpression",
    #                                                         ["evalRelationalExpression",
    #                                                           ["concatenationExpr",
    #                                                             ["additiveExpression",
    #                                                               ["multiplyExpression",
    #                                                                 ["unaryExpression",
    #                                                                   ["constant",
    #                                                                     ["numberconstant",
    #                                                                       ["number", "0"]]]]]]]]]]]]]]]]]],
    #                                     ",",
    #                                     ["libFunctionArgItem",
    #                                       ["expressionWithTime",
    #                                         ["expressionQualifyable",
    #                                           ["expression",
    #                                             ["caseExpression",
    #                                               ["evalOrExpression",
    #                                                 ["evalAndExpression",
    #                                                   ["bitWiseExpression",
    #                                                     ["negatedExpression",
    #                                                       ["evalEqualsExpression",
    #                                                         ["evalRelationalExpression",
    #                                                           ["concatenationExpr",
    #                                                             ["additiveExpression",
    #                                                               ["multiplyExpression",
    #                                                                 ["unaryExpression",
    #                                                                   ["constant",
    #                                                                     ["numberconstant",
    #                                                                       ["number", "8"]]]]]]]]]]]]]]]]]]],
    #                                   ")"]]]]]]]]]]],
    #             "AND",
    #             ["bitWiseExpression",
    #               ["negatedExpression",
    #                 ["evalEqualsExpression",
    #                   ["evalRelationalExpression",
    #                     ["concatenationExpr",
    #                       ["additiveExpression",
    #                         ["multiplyExpression",
    #                           ["unaryExpression",
    #                             ["builtinFunc",
    #                               "cast",
    #                               "(",
    #                               ["expression",
    #                                 ["caseExpression",
    #                                   ["evalOrExpression",
    #                                     ["evalAndExpression",
    #                                       ["bitWiseExpression",
    #                                         ["negatedExpression",
    #                                           ["evalEqualsExpression",
    #                                             ["evalRelationalExpression",
    #                                               ["concatenationExpr",
    #                                                 ["additiveExpression",
    #                                                   ["multiplyExpression",
    #                                                     ["unaryExpression",
    #                                                       ["eventPropertyOrLibFunction",
    #                                                         ["eventProperty",
    #                                                           ["eventPropertyAtomic",
    #                                                             ["eventPropertyIdent",
    #                                                               ["keywordAllowedIdent", "PINChangeEvent"]]],
    #                                                           ".",
    #                                                           ["eventPropertyAtomic",
    #                                                             ["eventPropertyIdent",
    #                                                               ["keywordAllowedIdent", "size"]]]]]]]]]]]]]]]]],
    #                               ",",
    #                               ["classIdentifier", ["escapableStr", "double"]],
    #                               ")"]]]]],
    #                     ">",
    #                     ["concatenationExpr",
    #                       ["additiveExpression",
    #                         ["multiplyExpression",
    #                           ["unaryExpression",
    #                             ["constant",
    #                               ["numberconstant", ["number", "10.5"]]]]]]]]]]]]]]]],
    #   "<EOF>"]

    ### SELECT count(*) AS cnt
    ### FROM TestTable.win:time_batch(10 sec)
    ### WHERE params.$$path.$1="/" AND size.$0.bytes > 100 and opts.num.seq.length() > 0

    # ["startEPLExpressionRule",
    #   ["eplExpression",
    #     ["selectExpr",
    #       "SELECT",
    #       ["selectClause",
    #         ["selectionList",
    #           ["selectionListElement",
    #             ["selectionListElementExpr",
    #               ["expression",
    #                 ["caseExpression",
    #                   ["evalOrExpression",
    #                     ["evalAndExpression",
    #                       ["bitWiseExpression",
    #                         ["negatedExpression",
    #                           ["evalEqualsExpression",
    #                             ["evalRelationalExpression",
    #                               ["concatenationExpr",
    #                                 ["additiveExpression",
    #                                   ["multiplyExpression",
    #                                     ["unaryExpression",
    #                                       ["builtinFunc", "count", "(", "*", ")"]]]]]]]]]]]]],
    #               "AS",
    #               ["keywordAllowedIdent", "cnt"]]]]],
    #       "FROM",
    #       ["fromClause",
    #         ["streamExpression",
    #           ["eventFilterExpression",
    #             ["classIdentifier", ["escapableStr", "TestTable"]]],
    #           ".",
    #           ["viewExpression",
    #             "win",
    #             ":",
    #             "time_batch",
    #             "(",
    #             ["expressionWithTimeList",
    #               ["expressionWithTimeInclLast",
    #                 ["expressionWithTime",
    #                   ["timePeriod",
    #                     ["secondPart", ["numberconstant", ["number", "10"]], "sec"]]]]],
    #             ")"]],
    #         "regularJoin"],
    #       "WHERE",
    #       ["whereClause",
    #         ["evalOrExpression",
    #           ["evalAndExpression",
    #             ["bitWiseExpression",
    #               ["negatedExpression",
    #                 ["evalEqualsExpression",
    #                   ["evalRelationalExpression",
    #                     ["concatenationExpr",
    #                       ["additiveExpression",
    #                         ["multiplyExpression",
    #                           ["unaryExpression",
    #                             ["eventPropertyOrLibFunction",
    #                               ["eventProperty",
    #                                 ["eventPropertyAtomic",
    #                                   ["eventPropertyIdent", ["keywordAllowedIdent", "params"]]],
    #                                 ".",
    #                                 ["eventPropertyAtomic",
    #                                   ["eventPropertyIdent", ["keywordAllowedIdent", "$$path"]]],
    #                                 ".",
    #                                 ["eventPropertyAtomic",
    #                                   ["eventPropertyIdent", ["keywordAllowedIdent", "$1"]]]]]]]]]],
    #                   "=",
    #                   ["evalRelationalExpression",
    #                     ["concatenationExpr",
    #                       ["additiveExpression",
    #                         ["multiplyExpression",
    #                           ["unaryExpression",
    #                             ["constant", ["stringconstant", "\"/\""]]]]]]]]]],
    #             "AND",
    #             ["bitWiseExpression",
    #               ["negatedExpression",
    #                 ["evalEqualsExpression",
    #                   ["evalRelationalExpression",
    #                     ["concatenationExpr",
    #                       ["additiveExpression",
    #                         ["multiplyExpression",
    #                           ["unaryExpression",
    #                             ["eventPropertyOrLibFunction",
    #                               ["eventProperty",
    #                                 ["eventPropertyAtomic",
    #                                   ["eventPropertyIdent", ["keywordAllowedIdent", "size"]]],
    #                                 ".",
    #                                 ["eventPropertyAtomic",
    #                                   ["eventPropertyIdent", ["keywordAllowedIdent", "$0"]]],
    #                                 ".",
    #                                 ["eventPropertyAtomic",
    #                                   ["eventPropertyIdent",
    #                                     ["keywordAllowedIdent", "bytes"]]]]]]]]],
    #                     ">",
    #                     ["concatenationExpr",
    #                       ["additiveExpression",
    #                         ["multiplyExpression",
    #                           ["unaryExpression",
    #                             ["constant", ["numberconstant", ["number", "100"]]]]]]]]]]],
    #             "and",
    #             ["bitWiseExpression",
    #               ["negatedExpression",
    #                 ["evalEqualsExpression",
    #                   ["evalRelationalExpression",
    #                     ["concatenationExpr",
    #                       ["additiveExpression",
    #                         ["multiplyExpression",
    #                           ["unaryExpression",
    #                             ["eventPropertyOrLibFunction",
    #                               ["libFunction",
    #                                 ["libFunctionWithClass",
    #                                   ["classIdentifier",
    #                                     ["escapableStr", "opts"],
    #                                     ".",
    #                                     ["escapableStr", "num"],
    #                                     ".",
    #                                     ["escapableStr", "seq"]],
    #                                   ".",
    #                                   ["funcIdentTop", ["escapableIdent", "length"]],
    #                                   "(",
    #                                   ")"]]]]]]],
    #                     ">",
    #                     ["concatenationExpr",
    #                       ["additiveExpression",
    #                         ["multiplyExpression",
    #                           ["unaryExpression",
    #                             ["constant", ["numberconstant", ["number", "0"]]]]]]]]]]]]]]]],
    #   "<EOF>"]

    ### SELECT a.name, a.content, b.content
    ### FROM pattern[every a=EventA -> b=EventA(name = a.name, type = 'TYPE') WHERE timer:within(1 min)].win:time(2 hour)
    ### WHERE a.source in ('A', 'B')

    # ["startEPLExpressionRule",
    #   ["eplExpression",
    #     ["selectExpr",
    #       "SELECT",
    #       ["selectClause",
    #         ["selectionList",
    #           ["selectionListElement",
    #             ["selectionListElementExpr",
    #               ["expression",
    #                 ["caseExpression",
    #                   ["evalOrExpression",
    #                     ["evalAndExpression",
    #                       ["bitWiseExpression",
    #                         ["negatedExpression",
    #                           ["evalEqualsExpression",
    #                             ["evalRelationalExpression",
    #                               ["concatenationExpr",
    #                                 ["additiveExpression",
    #                                   ["multiplyExpression",
    #                                     ["unaryExpression",
    #                                       ["eventPropertyOrLibFunction",
    #                                         ["eventProperty",
    #                                           ["eventPropertyAtomic",
    #                                             ["eventPropertyIdent", ["keywordAllowedIdent", "a"]]],
    #                                           ".",
    #                                           ["eventPropertyAtomic",
    #                                             ["eventPropertyIdent",
    #                                               ["keywordAllowedIdent", "name"]]]]]]]]]]]]]]]]]]],
    #           ",",
    #           ["selectionListElement",
    #             ["selectionListElementExpr",
    #               ["expression",
    #                 ["caseExpression",
    #                   ["evalOrExpression",
    #                     ["evalAndExpression",
    #                       ["bitWiseExpression",
    #                         ["negatedExpression",
    #                           ["evalEqualsExpression",
    #                             ["evalRelationalExpression",
    #                               ["concatenationExpr",
    #                                 ["additiveExpression",
    #                                   ["multiplyExpression",
    #                                     ["unaryExpression",
    #                                       ["eventPropertyOrLibFunction",
    #                                         ["eventProperty",
    #                                           ["eventPropertyAtomic",
    #                                             ["eventPropertyIdent", ["keywordAllowedIdent", "a"]]],
    #                                           ".",
    #                                           ["eventPropertyAtomic",
    #                                             ["eventPropertyIdent",
    #                                               ["keywordAllowedIdent", "content"]]]]]]]]]]]]]]]]]]],
    #           ",",
    #           ["selectionListElement",
    #             ["selectionListElementExpr",
    #               ["expression",
    #                 ["caseExpression",
    #                   ["evalOrExpression",
    #                     ["evalAndExpression",
    #                       ["bitWiseExpression",
    #                         ["negatedExpression",
    #                           ["evalEqualsExpression",
    #                             ["evalRelationalExpression",
    #                               ["concatenationExpr",
    #                                 ["additiveExpression",
    #                                   ["multiplyExpression",
    #                                     ["unaryExpression",
    #                                       ["eventPropertyOrLibFunction",
    #                                         ["eventProperty",
    #                                           ["eventPropertyAtomic",
    #                                             ["eventPropertyIdent", ["keywordAllowedIdent", "b"]]],
    #                                           ".",
    #                                           ["eventPropertyAtomic",
    #                                             ["eventPropertyIdent",
    #                                               ["keywordAllowedIdent", "content"]]]]]]]]]]]]]]]]]]]]],
    #       "FROM",
    #       ["fromClause",
    #         ["streamExpression",
    #           ["patternInclusionExpression",
    #             "pattern",
    #             "[",
    #             ["patternExpression",
    #               ["followedByExpression",
    #                 ["orExpression",
    #                   ["andExpression",
    #                     ["matchUntilExpression",
    #                       ["qualifyExpression",
    #                         "every",
    #                         ["guardPostFix",
    #                           ["atomicExpression",
    #                             ["patternFilterExpression",
    #                               "a",
    #                               "=",
    #                               ["classIdentifier", ["escapableStr", "EventA"]]]]]]]]],
    #                 ["followedByRepeat",
    #                   "->",
    #                   ["orExpression",
    #                     ["andExpression",
    #                       ["matchUntilExpression",
    #                         ["qualifyExpression",
    #                           ["guardPostFix",
    #                             ["atomicExpression",
    #                               ["patternFilterExpression",
    #                                 "b",
    #                                 "=",
    #                                 ["classIdentifier", ["escapableStr", "EventA"]],
    #                                 "(",
    #                                 ["expressionList",
    #                                   ["expression",
    #                                     ["caseExpression",
    #                                       ["evalOrExpression",
    #                                         ["evalAndExpression",
    #                                           ["bitWiseExpression",
    #                                             ["negatedExpression",
    #                                               ["evalEqualsExpression",
    #                                                 ["evalRelationalExpression",
    #                                                   ["concatenationExpr",
    #                                                     ["additiveExpression",
    #                                                       ["multiplyExpression",
    #                                                         ["unaryExpression",
    #                                                           ["eventPropertyOrLibFunction",
    #                                                             ["eventProperty",
    #                                                               ["eventPropertyAtomic",
    #                                                                 ["eventPropertyIdent",
    #                                                                   ["keywordAllowedIdent", "name"]]]]]]]]]],
    #                                                 "=",
    #                                                 ["evalRelationalExpression",
    #                                                   ["concatenationExpr",
    #                                                     ["additiveExpression",
    #                                                       ["multiplyExpression",
    #                                                         ["unaryExpression",
    #                                                           ["eventPropertyOrLibFunction",
    #                                                             ["eventProperty",
    #                                                               ["eventPropertyAtomic",
    #                                                                 ["eventPropertyIdent",
    #                                                                   ["keywordAllowedIdent", "a"]]],
    #                                                               ".",
    #                                                               ["eventPropertyAtomic",
    #                                                                 ["eventPropertyIdent",
    #                                                                   ["keywordAllowedIdent",
    #                                                                     "name"]]]]]]]]]]]]]]]]],
    #                                   ",",
    #                                   ["expression",
    #                                     ["caseExpression",
    #                                       ["evalOrExpression",
    #                                         ["evalAndExpression",
    #                                           ["bitWiseExpression",
    #                                             ["negatedExpression",
    #                                               ["evalEqualsExpression",
    #                                                 ["evalRelationalExpression",
    #                                                   ["concatenationExpr",
    #                                                     ["additiveExpression",
    #                                                       ["multiplyExpression",
    #                                                         ["unaryExpression",
    #                                                           ["eventPropertyOrLibFunction",
    #                                                             ["eventProperty",
    #                                                               ["eventPropertyAtomic",
    #                                                                 ["eventPropertyIdent",
    #                                                                   ["keywordAllowedIdent", "type"]]]]]]]]]],
    #                                                 "=",
    #                                                 ["evalRelationalExpression",
    #                                                   ["concatenationExpr",
    #                                                     ["additiveExpression",
    #                                                       ["multiplyExpression",
    #                                                         ["unaryExpression",
    #                                                           ["constant",
    #                                                             ["stringconstant", "'TYPE'"]]]]]]]]]]]]]]],
    #                                 ")"]],
    #                             "WHERE",
    #                             ["guardWhereExpression",
    #                               "timer",
    #                               ":",
    #                               "within",
    #                               "(",
    #                               ["expressionWithTimeList",
    #                                 ["expressionWithTimeInclLast",
    #                                   ["expressionWithTime",
    #                                     ["timePeriod",
    #                                       ["minutePart",
    #                                         ["numberconstant", ["number", "1"]],
    #                                         "min"]]]]],
    #                               ")"]]]]]]]]],
    #             "]"],
    #           ".",
    #           ["viewExpression",
    #             "win",
    #             ":",
    #             "time",
    #             "(",
    #             ["expressionWithTimeList",
    #               ["expressionWithTimeInclLast",
    #                 ["expressionWithTime",
    #                   ["timePeriod",
    #                     ["hourPart", ["numberconstant", ["number", "2"]], "hour"]]]]],
    #             ")"]],
    #         "regularJoin"],
    #       "WHERE",
    #       ["whereClause",
    #         ["evalOrExpression",
    #           ["evalAndExpression",
    #             ["bitWiseExpression",
    #               ["negatedExpression",
    #                 ["evalEqualsExpression",
    #                   ["evalRelationalExpression",
    #                     ["concatenationExpr",
    #                       ["additiveExpression",
    #                         ["multiplyExpression",
    #                           ["unaryExpression",
    #                             ["eventPropertyOrLibFunction",
    #                               ["eventProperty",
    #                                 ["eventPropertyAtomic",
    #                                   ["eventPropertyIdent", ["keywordAllowedIdent", "a"]]],
    #                                 ".",
    #                                 ["eventPropertyAtomic",
    #                                   ["eventPropertyIdent",
    #                                     ["keywordAllowedIdent", "source"]]]]]]]]],
    #                     "in",
    #                     "(",
    #                     ["expression",
    #                       ["caseExpression",
    #                         ["evalOrExpression",
    #                           ["evalAndExpression",
    #                             ["bitWiseExpression",
    #                               ["negatedExpression",
    #                                 ["evalEqualsExpression",
    #                                   ["evalRelationalExpression",
    #                                     ["concatenationExpr",
    #                                       ["additiveExpression",
    #                                         ["multiplyExpression",
    #                                           ["unaryExpression",
    #                                             ["constant", ["stringconstant", "'A'"]]]]]]]]]]]]]],
    #                     ",",
    #                     ["expression",
    #                       ["caseExpression",
    #                         ["evalOrExpression",
    #                           ["evalAndExpression",
    #                             ["bitWiseExpression",
    #                               ["negatedExpression",
    #                                 ["evalEqualsExpression",
    #                                   ["evalRelationalExpression",
    #                                     ["concatenationExpr",
    #                                       ["additiveExpression",
    #                                         ["multiplyExpression",
    #                                           ["unaryExpression",
    #                                             ["constant", ["stringconstant", "'B'"]]]]]]]]]]]]]],
    #                     ")"]]]]]]]]],
    #   "<EOF>"]

    #### SELECT a,NULLABLE(b),COUNT(DISTINCT NULLABLE(c)) FROM t GROUP BY a,NULLABLE(b)

    # ["startEPLExpressionRule",
    #   ["eplExpression",
    #     ["selectExpr",
    #       "SELECT",
    #       ["selectClause",
    #         ["selectionList",
    #           ["selectionListElement",
    #             ["selectionListElementExpr",
    #               ["expression",
    #                 ["caseExpression",["evalOrExpression",["evalAndExpression",["bitWiseExpression",["negatedExpression",
    #                   ["evalEqualsExpression",["evalRelationalExpression",["concatenationExpr",["additiveExpression",
    #                     ["multiplyExpression",["unaryExpression",
    #                       ["eventPropertyOrLibFunction",
    #                         ["eventProperty",
    #                           ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "a"]]]]]]]]]]]]]]]]]]],
    #           ",",
    #           ["selectionListElement",
    #             ["selectionListElementExpr",
    #               ["expression",
    #                 ["caseExpression",["evalOrExpression",["evalAndExpression",["bitWiseExpression",["negatedExpression",
    #                   ["evalEqualsExpression",["evalRelationalExpression",["concatenationExpr",["additiveExpression",
    #                     ["multiplyExpression",["unaryExpression",
    #                       ["eventPropertyOrLibFunction",
    #                         ["libFunction",
    #                           ["libFunctionWithClass",
    #                             ["funcIdentTop", ["escapableIdent", "NULLABLE"]],
    #                               "(",
    #                               ["libFunctionArgs",
    #                                 ["libFunctionArgItem",
    #                                   ["expressionWithTime",
    #                                     ["expressionQualifyable",
    #                                       ["expression",
    #                                         ["caseExpression",["evalOrExpression",["evalAndExpression",["bitWiseExpression",
    #                                           ["negatedExpression",["evalEqualsExpression",["evalRelationalExpression",
    #                                             ["concatenationExpr",["additiveExpression",["multiplyExpression",["unaryExpression",
    #                                               ["eventPropertyOrLibFunction",
    #                                                 ["eventProperty",
    #                                                   ["eventPropertyAtomic",
    #                                                     ["eventPropertyIdent", ["keywordAllowedIdent", "b"]]]]]]]]]]]]]]]]]]]]],
    #                               ")"]]]]]]]]]]]]]]]]],
    #           ",",
    #           ["selectionListElement",
    #             ["selectionListElementExpr",
    #               ["expression",
    #                 ["caseExpression",["evalOrExpression",["evalAndExpression",["bitWiseExpression",["negatedExpression",
    #                   ["evalEqualsExpression",["evalRelationalExpression",["concatenationExpr",["additiveExpression",
    #                     ["multiplyExpression",["unaryExpression",
    #                       ["builtinFunc",
    #                         "COUNT",
    #                         "(",
    #                         "DISTINCT",
    #                         ["expression",
    #                           ["caseExpression",["evalOrExpression",["evalAndExpression",["bitWiseExpression",
    #                             ["negatedExpression",["evalEqualsExpression",["evalRelationalExpression",
    #                               ["concatenationExpr",["additiveExpression",["multiplyExpression",["unaryExpression",
    #                                 ["eventPropertyOrLibFunction",
    #                                   ["libFunction",
    #                                     ["libFunctionWithClass",
    #                                       ["funcIdentTop", ["escapableIdent", "NULLABLE"]],
    #                                         "(",
    #                                         ["libFunctionArgs",
    #                                           ["libFunctionArgItem",
    #                                             ["expressionWithTime",
    #                                               ["expressionQualifyable",
    #                                                 ["expression",
    #                                                   ["caseExpression",["evalOrExpression",["evalAndExpression",["bitWiseExpression",
    #                                                     ["negatedExpression",["evalEqualsExpression",["evalRelationalExpression",
    #                                                       ["concatenationExpr",["additiveExpression",["multiplyExpression",
    #                                                         ["unaryExpression",
    #                                                           ["eventPropertyOrLibFunction",
    #                                                             ["eventProperty",
    #                                                               ["eventPropertyAtomic",
    #                                                                 ["eventPropertyIdent",
    #                                                                   ["keywordAllowedIdent", "c"]]]]]]]]]]]]]]]]]]]]],
    #                                                                       ")"]]]]]]]]]]]]]]],
    #                                         ")"]]]]]]]]]]]]]]]]],
    #       "FROM",
    #       ["fromClause",
    #         ["streamExpression", ["eventFilterExpression", ["classIdentifier", ["escapableStr", "t"]]]],
    #         "regularJoin"],
    #       "GROUP",
    #       "BY",
    #       ["groupByListExpr",
    #         ["groupByListChoice",
    #           ["expression",
    #             ["caseExpression",["evalOrExpression",["evalAndExpression",["bitWiseExpression",["negatedExpression",
    #               ["evalEqualsExpression",["evalRelationalExpression",["concatenationExpr",["additiveExpression",
    #                 ["multiplyExpression",["unaryExpression",
    #                   ["eventPropertyOrLibFunction",
    #                     ["eventProperty",
    #                       ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "a"]]]]]]]]]]]]]]]]]],
    #         ",",
    #         ["groupByListChoice",
    #           ["expression",
    #             ["caseExpression",["evalOrExpression",["evalAndExpression",["bitWiseExpression",["negatedExpression",
    #               ["evalEqualsExpression",["evalRelationalExpression",["concatenationExpr",["additiveExpression",
    #                 ["multiplyExpression",["unaryExpression",
    #                   ["eventPropertyOrLibFunction",
    #                     ["libFunction",
    #                       ["libFunctionWithClass",
    #                         ["funcIdentTop", ["escapableIdent", "NULLABLE"]],
    #                         "(",
    #                         ["libFunctionArgs",
    #                           ["libFunctionArgItem",
    #                             ["expressionWithTime",
    #                               ["expressionQualifyable",
    #                                 ["expression",
    #                                   ["caseExpression",["evalOrExpression",["evalAndExpression",["bitWiseExpression",
    #                                     ["negatedExpression",["evalEqualsExpression",["evalRelationalExpression",
    #                                       ["concatenationExpr",["additiveExpression",["multiplyExpression",["unaryExpression",
    #                                         ["eventPropertyOrLibFunction",
    #                                           ["eventProperty",
    #                                             ["eventPropertyAtomic",
    #                                               ["eventPropertyIdent", ["keywordAllowedIdent", "b"]]]]]]]]]]]]]]]]]]]]],
    #                                         ")"]]]]]]]]]]]]]]]]]]],
    #   "<EOF>"]

    def astnode(tree)
      # com.espertech.esper.epl.generated.EsperEPL2GrammarParser.ruleNames[ast.ruleIndex] #=> "startEPLExpressionRule"
      # com.espertech.esper.epl.generated.EsperEPL2GrammarParser.ruleNames[ast.getChild(0).ruleIndex] #=> "eplExpression"

      # ast.getChild(0).getChild(0).ruleIndex #=> 15
      # com.espertech.esper.epl.generated.EsperEPL2GrammarParser.ruleNames[ast.getChild(0).getChild(0).ruleIndex] #=> "selectExpr"
      # ast.getChild(0).getChild(0).getChild(0).symbol.text #=> 'select'
      # ast.getChild(0).getChild(0).getChild(0).symbol.type #=> 24

      # [23] pry(main)> ast.getChild(0).getChild(1)
      # => nil
      # [24] pry(main)> ast.getChild(0).getChild(0).getChild(1)
      # => #<Java::ComEspertechEsperEplGenerated::EsperEPL2GrammarParser::SelectClauseContext:0x6437693>
      # [25] pry(main)> ast.getChild(0).getChild(0).getChild(1).getChild(0)
      # => #<Java::ComEspertechEsperEplGenerated::EsperEPL2GrammarParser::SelectionListContext:0x5de28c04>

      name = if tree.respond_to?(:getRuleIndex)
               Java::ComEspertechEsperEplGenerated::EsperEPL2GrammarParser.ruleNames[tree.getRuleIndex]
             else
               tree.symbol.text
             end
      children = []
      tree.childCount.times do |i|
        child = tree.getChild(i)
        children << astnode(child) if child
      end

      cls = case name
            when 'expression' then ASTExpression
            when 'eventProperty' then ASTEventPropNode
            when 'selectionListElementExpr' then ASTSelectionElementNode
            when 'libFunction' then ASTLibFunctionNode
            when 'libFunctionArgItem' then ASTLibFunctionArgItemNode
            when 'streamExpression', 'subSelectFilterExpr' then ASTStreamNode
            when 'patternFilterExpression' then ASTPatternNode
            when 'subQueryExpr' then ASTSubSelectNode
            else ASTNode
            end
      if cls.respond_to?(:generate)
        cls.generate(name, children, tree)
      else
        cls.new(name, children, tree)
      end
    end

    class ASTNode
      attr_accessor :name, :children, :tree

      def initialize(name, children, tree)
        @name = name
        @children = children
        @tree = tree
      end

      def has_a?(name)
        @children.size == 1 && (@children.first.name == name || @children.first.nodetype?(name))
      end

      def chain(*nodes)
        nodes.reduce(self){|n, next_node| n && n.has_a?(next_node) ? n.child : nil }
      end

      def nodetype?(*sym)
        false
      end

      def to_a
        [@name] + @children.map{|c| c.children.size > 0 ? c.to_a : c.name}
      end

      def child
        @children.first
      end

      def find(type) # only one, depth-first search
        return self if type.is_a?(String) && @name == type || nodetype?(type)

        @children.each do |c|
          next if type != :subquery && c.nodetype?(:subquery)
          r = c.find(type)
          return r if r
        end
        nil
      end

      def listup(*type) # search all nodes that has 'type'
        if type.size > 1
          return type.map{|t| self.listup(t) }.reduce(&:+)
        end
        type = type.first

        result = []
        result.push(self) if type.is_a?(String) && @name == type || nodetype?(type)

        @children.each do |c|
          next if type != :subquery && c.nodetype?(:subquery)
          result.push(*c.listup(type))
        end
        result
      end

      def fields(default_target=nil, known_targets_aliases=[])
        @children.map{|c| c.nodetype?(:subquery) ? [] : c.fields(default_target, known_targets_aliases)}.reduce(&:+) || []
      end
    end

    class ASTExpression < ASTNode
      # ["expression",
      #   ["caseExpression", ["evalOrExpression", ["evalAndExpression", ["bitWiseExpression", ["negatedExpression",
      #     ["evalEqualsExpression", ["evalRelationalExpression", ["concatenationExpr", ["additiveExpression",
      #       ["multiplyExpression", ["unaryExpression", ["eventPropertyOrLibFunction",
      #         ["eventProperty",
      #           ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "s"]]]]]]]]]]]]]]]]]]]
      def nodetype?(*sym)
        sym.include?(:expression)
      end

      SIMPLE_PROPERTY_REFERENCE_NODES = [
        "caseExpression", "evalOrExpression", "evalAndExpression", "bitWiseExpression", "negatedExpression",
        "evalEqualsExpression", "evalRelationalExpression", "concatenationExpr", "additiveExpression",
        "multiplyExpression", "unaryExpression", "eventPropertyOrLibFunction", "eventProperty"
      ]
      def propertyReference?
        end_node = self.chain(*SIMPLE_PROPERTY_REFERENCE_NODES)
        end_node && end_node.nodetype?(:property)
      end
    end

    class ASTEventPropNode < ASTNode # eventProperty
      ### "a"
      # ["eventProperty", ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "a"]]]

      ### "fraud.aaa"
      # ["eventProperty",
      #   ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "fraud"]]],
      #   ".",
      #   ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "aaa"]]]]

      ### "size.$0.bytes"
      # ["eventProperty",
      #   ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "size"]]],
      #   ".",
      #   ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "$0"]]],
      #   ".",
      #   ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "bytes"]]]]

      ### "field.index("?")"
      # ["eventProperty",
      #   ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "field"]]],
      #   ".",
      #   ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "index"]], "(", "'?'", ")"]]

      ### "field.f1.index(".")"
      # ["eventProperty",
      #   ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "field"]]],
      #   ".",
      #   ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "f1"]]],
      #   ".",
      #   ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "index"]], "(", "'.'", ")"]]

      #### escapes: Oops!!!! unsupported yet.

      ### "`path name`"
      #    ["eventProperty", ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "`field name`"]]]]

      ### "`T Table`.`path name`"
      # ["eventProperty",
      #   ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "`T table`"]]],
      #   ".",
      #   ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "`path name`"]]]]

      ### "`size.num`"
      # ["eventProperty", ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "`size.num`"]]]]

      def nodetype?(*sym)
        sym.include?(:prop) || sym.include?(:property)
      end

      def fields(default_target=nil, known_targets_aliases=[])
        props = self.listup('eventPropertyAtomic')
        leading_name = props[0].find('eventPropertyIdent').find('keywordAllowedIdent').child.name

        if props.size > 1 # alias.fieldname or container_fieldname.key.$1 or fieldname.method(...)
          non_calls = props.select{|p| p.children.size == 1 }.map{|p| p.find('eventPropertyIdent').find('keywordAllowedIdent').child.name }
          if known_targets_aliases.include?(leading_name)
            [ {:f => non_calls[1..-1].join("."), :t => leading_name} ]
          else
            [ {:f => non_calls.join("."), :t => default_target} ]
          end
        else # fieldname (default target)
          # ["eventProperty", ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "a"]]]
          [ {:f => leading_name, :t => default_target } ]
        end
      end
    end

    class ASTSelectionElementNode < ASTNode # selectionListElementExpr
      ### "s"
      # ["selectionListElement",
      #   ["selectionListElementExpr",
      #     ["expression",
      #       ["caseExpression", ["evalOrExpression", ["evalAndExpression", ["bitWiseExpression", ["negatedExpression",
      #         ["evalEqualsExpression", ["evalRelationalExpression", ["concatenationExpr", ["additiveExpression",
      #           ["multiplyExpression", ["unaryExpression", ["eventPropertyOrLibFunction",
      #             ["eventProperty",
      #               ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "s"]]]]]]]]]]]]]]]]]]]

      ### "count(*) AS cnt"
      # ["selectionListElementExpr",
      #   ["expression",
      #     ["caseExpression", ["evalOrExpression", ["evalAndExpression", ["bitWiseExpression", ["negatedExpression",
      #       ["evalEqualsExpression", ["evalRelationalExpression", ["concatenationExpr", ["additiveExpression",
      #         ["multiplyExpression", ["unaryExpression",
      #           ["builtinFunc", "count", "(", "*", ")"]]]]]]]]]]]]],
      #   "AS",
      #   ["keywordAllowedIdent", "cnt"]]

      ### "n.s as s"
      # ["selectionListElementExpr",
      #   ["expression",
      #     ["caseExpression", ["evalOrExpression", ["evalAndExpression", ["bitWiseExpression", ["negatedExpression",
      #       ["evalEqualsExpression", ["evalRelationalExpression", ["concatenationExpr", ["additiveExpression",
      #         ["multiplyExpression", ["unaryExpression", ["eventPropertyOrLibFunction",
      #           ["eventProperty",
      #             ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "n"]]],
      #             ".",
      #             ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "s"]]]]]]]]]]]]]]]]],
      #   "as",
      #   ["keywordAllowedIdent", "s"]]]

      def nodetype?(*sym)
        sym.include?(:selection)
      end

      def alias
        @children.size == 3 && @children[1].name.downcase == 'as' ? @children[2].child.name : nil
      end
    end

    class ASTLibFunctionNode < ASTNode # LIB_FUNCTION
      ### NULLABLE field!
      # ["libFunction",
      #   ["libFunctionWithClass",
      #     ["funcIdentTop", ["escapableIdent", "NULLABLE"]],
      #     "(",
      #     ["libFunctionArgs",["libFunctionArgItem",["expressionWithTime",["expressionQualifyable",
      #       ["expression",
      #         ["caseExpression",["evalOrExpression",["evalAndExpression",["bitWiseExpression",["negatedExpression",
      #           ["evalEqualsExpression",["evalRelationalExpression",["concatenationExpr",["additiveExpression",
      #             ["multiplyExpression",["unaryExpression",
      #               ["eventPropertyOrLibFunction",
      #                 ["eventProperty",
      #                   ["eventPropertyAtomic",
      #                     ["eventPropertyIdent", ["keywordAllowedIdent", "b"]]]]]]]]]]]]]]]]]]]]],
      #     ")"]]]

      ### foo is function
      # "foo()"     => ["libFunction", ["libFunctionWithClass", ["funcIdentTop", ["escapableIdent", "foo"]], "(", ")"]]

      ### "foo(10)"
      # ["libFunction",
      #   ["libFunctionWithClass",
      #     ["funcIdentTop", ["escapableIdent", "foo"]],
      #     "(",
      #     ["libFunctionArgs",
      #       ["libFunctionArgItem", ["expressionWithTime", ["expressionQualifyable", ["expression", EXPRESSION... ]]]]]
      #     ")"]]

      ### "foo(10,0)"
      # ["libFunction",
      #   ["libFunctionWithClass",
      #     ["funcIdentTop", ["escapableIdent", "foo"]],
      #     "(",
      #     ["libFunctionArgs",
      #       ["libFunctionArgItem", ["expressionWithTime", ["expressionQualifyable", ["expression", EXPRESSION... ]]]],
      #       ",",
      #       ["libFunctionArgItem", ["expressionWithTime", ["expressionQualifyable", ["expression", EXPRESSION... ]]]]],
      #     ")"]]

      ### foo(value)
      # ["libFunction",
      #   ["libFunctionWithClass",
      #     ["funcIdentTop", ["escapableIdent", "FOO"]],
      #     "(",
      #     ["libFunctionArgs",
      #       ["libFunctionArgItem",
      #         ["expressionWithTime",
      #           ["expressionQualifyable",
      #             ["expression",
      #               ["caseExpression",["evalOrExpression",["evalAndExpression",["bitWiseExpression",["negatedExpression",
      #                 ["evalEqualsExpression",["evalRelationalExpression",["concatenationExpr",["additiveExpression",
      #                   ["multiplyExpression",["unaryExpression",
      #                     ["eventPropertyOrLibFunction",
      #                       ["eventProperty",
      #                         ["eventPropertyAtomic",
      #                           ["eventPropertyIdent", ["keywordAllowedIdent", "value"]]]]]]]]]]]]]]]]]]]]],
      #     ")"]]

      ### foo is property
      ### "foo.bar()"
      # ["libFunction",
      #   ["libFunctionWithClass",
      #     ["classIdentifier", ["escapableStr", "foo"]],
      #     ".",
      #     ["funcIdentTop", ["escapableIdent", "bar"]],
      #     "(",
      #     ")"]]

      ### Math.abs()
      # ["libFunction",
      #   ["libFunctionWithClass",
      #     ["classIdentifier", ["escapableStr", "Math"]],
      #     ".",
      #     ["funcIdentTop", ["escapableIdent", "abs"]],
      #     "(",
      #     ["libFunctionArgs",
      #       ["libFunctionArgItem",
      #         ["expressionWithTime",
      #           ["expression", EXPRESSION... ]]]],
      #     ")"]]

      ### "foo.bar(0)"
      # ["libFunction",
      #   ["libFunctionWithClass",
      #     ["classIdentifier", ["escapableStr", "foo"]],
      #     ".",
      #     ["funcIdentTop", ["escapableIdent", "bar"]],
      #     "(",
      #     ["libFunctionArgs",
      #       ["libFunctionArgItem",
      #         ["expressionWithTime",
      #           ["expressionQualifyable",
      #             ["expression", EXPRESSION....
      #               ["constant", ["numberconstant", ["number", "0"]]]]]]]],
      #     ")"]]

      ### chain
      ### "field.substr(0).length()"
      # ["libFunction",
      #   ["libFunctionWithClass",
      #     ["classIdentifier", ["escapableStr", "field"]],
      #     ".",
      #     ["funcIdentTop", ["escapableIdent", "substr"]],
      #     "(",
      #     ["libFunctionArgs",
      #       ["libFunctionArgItem",
      #         ["expressionWithTime",
      #           ["expressionQualifyable",
      #             ["expression", EXPRESSION...,
      #               ["constant", ["numberconstant", ["number", "0"]]]]]]]],
      #     ")"],
      #   ".",
      #   ["libFunctionNoClass",
      #     ["funcIdentChained", ["escapableIdent", "length"]],
      #     "(",
      #     ")"]]

      ### nested function call
      # ["libFunction",
      #   ["libFunctionWithClass",
      #     ["classIdentifier", ["escapableStr", "Math"]],
      #     ".",
      #     ["funcIdentTop", ["escapableIdent", "abs"]],
      #     "(",
      #     ["libFunctionArgs",
      #       ["libFunctionArgItem",
      #         ["expressionWithTime",
      #           ["expressionQualifyable",
      #             ["expression", EXPRESSION...,
      #               ["eventPropertyOrLibFunction",
      #                 ["libFunction",
      #                   ["libFunctionWithClass",
      #                     ["classIdentifier",
      #                       ["escapableStr", "Math"]],
      #                     ".",
      #                     ["funcIdentTop",
      #                       ["escapableIdent", "abs"]],
      #                     "(",
      #                     ["libFunctionArgs",
      #                       ["libFunctionArgItem",
      #                         ["expressionWithTime",
      #                           ["expressionQualifyable",
      #                             ["expression", EXPRESSION...,
      #                               ["eventPropertyOrLibFunction",
      #                                 ["eventProperty",
      #                                   ["eventPropertyAtomic", ["eventPropertyIdent", ["keywordAllowedIdent", "a"]]]]]]]]]],
      #                     ")"]]]]]]]],
      #     ")"]]

      ### nested field access
      ### "foo.bar.$0.baz()"
      # ["libFunction",
      #   ["libFunctionWithClass",
      #     ["classIdentifier",
      #       ["escapableStr", "foo"],
      #       ".",
      #       ["escapableStr", "bar"],
      #       ".",
      #       ["escapableStr", "$0"]],
      #     ".",
      #     ["funcIdentTop", ["escapableIdent", "baz"]],
      #     "(",
      #     ")"]]

      ### escaped name access
      # "`T Table`.param.length()"
      # ["libFunction",
      #   ["libFunctionWithClass",
      #     ["classIdentifier",
      #       ["escapableStr", "`T Table`"],
      #       ".",
      #       ["escapableStr", "param"]],
      #     ".",
      #     ["funcIdentTop", ["escapableIdent", "length"]],
      #     "(",
      #     ")"]]

      def function_name
        f = self.find("funcIdentTop")
        if e = f.find("escapableIdent")
          e.child.name
        else
          f.child.name
        end
      end

      def nodetype?(*sym)
        sym.include?(:lib) || sym.include?(:libfunc)
      end

      def fields(default_target=nil, known_targets_aliases=[])
        # class identifier is receiver: "IDENT.func()"
        identifier = self.find("classIdentifier")
        if identifier
          if identifier.children.size == 1 && Norikra::Query.imported_java_class?(identifier.find("escapableStr").child.name)
            # Java imported class name (ex: 'Math.abs(-1)')
            self.listup(:prop).map{|c| c.fields(default_target, known_targets_aliases)}.reduce(&:+) || []
          else
            parts = identifier.listup('escapableStr').map{|node| node.child.name }
            target, fieldname = if parts.size == 1
                                  [ default_target, parts.first ]
                                elsif known_targets_aliases.include?( parts.first )
                                  [ parts[0], parts[1..-1].join(".") ]
                                else
                                  [ default_target, parts.join(".") ]
                                end
            children_list = self.listup(:prop).map{|c| c.fields(default_target, known_targets_aliases)}.reduce(&:+) || []
            [{:f => fieldname, :t => target}] + children_list
          end
        else
          if self.function_name.upcase == 'NULLABLE'
            props = self.listup(:prop).map{|c| c.fields(default_target, known_targets_aliases)}.reduce(&:+) || []
            props.each do |def_item|
              def_item[:n] = true # nullable: true
            end
            props
          else
            self.listup(:prop).map{|c| c.fields(default_target, known_targets_aliases)}.reduce(&:+) || []
          end
        end
      end
    end

    class ASTLibFunctionArgItemNode < ASTNode
      # ["libFunctionArgs",
      #   ["libFunctionArgItem",
      #     ["expressionWithTime",
      #       ["expressionQualifyable",
      #         ["expression", ... ]]]]
      def nodetype?(*sym)
        sym.include?(:libarg)
      end

      def expression
        self.chain("expressionWithTime", "expressionQualifyable", "expression")
      end
    end

    class ASTStreamNode < ASTNode # streamExpression, subSelectFilterExpr
      def self.generate(name, children, tree)
        if children.first.name == 'eventFilterExpression'
          ASTStreamEventNode.new(name, children, tree)
        elsif children.first.name == 'patternInclusionExpression'
          ASTStreamPatternNode.new(name, children, tree)
        else
          raise "unexpected stream node type! report to norikra developer!: #{children.map(&:name).join(',')}"
        end
      end

      def nodetype?(*sym)
        sym.include?(:stream)
      end

      def targets
        # ["TARGET_NAME"]
        raise NotImplementedError, "ASTStreamNode#targets MUST be overridden by subclass"
      end

      def aliases
        # [ [ "ALIAS_NAME", "TARGET_NAME" ], ... ]
        raise NotImplementedError, "ASTStreamNode#aliases MUST be overridden by subclass"
      end

      def fields(default_target=nil, known_targets_aliases=[])
        raise NotImplementedError, "ASTStreamNode#fields MUST be overridden by subclass"
      end
    end

    class ASTStreamEventNode < ASTStreamNode
      ##### from stream_def [as name] [unidirectional] [retain-union | retain-intersection],
      #####      [ stream_def ... ]
      #
      # single Event stream name ( ex: FROM events.win:time(...) AS e )

      # ["streamExpression",
      #   ["eventFilterExpression",
      #     ["classIdentifier", ["escapableStr", "TestTable"]]],
      #   ".",
      #   ["viewExpression",
      #     "win",
      #     ":",
      #     "time_batch",
      #     "(",
      #     ["expressionWithTimeList",
      #       ["expressionWithTimeInclLast",
      #         ["expressionWithTime",
      #           ["timePeriod",
      #             ["secondPart", ["numberconstant", ["number", "10"]], "sec"]]]]],
      #     ")"],
      # "regularJoin",

      # ["streamExpression",
      #   ["eventFilterExpression",
      #     ["classIdentifier", ["escapableStr", "FraudWarningEvent"]]],
      #   ".",
      #   ["viewExpression", "win", ":", "keepall", "(", ")"],
      #   "AS",
      #   "fraud"],
      # ["regularJoin",
      #   ",",
      #   ["streamExpression",
      #     ["eventFilterExpression",
      #       ["classIdentifier", ["escapableStr", "PINChangeEvent"]],
      #       "(",
      #       ["expressionList",
      #         ["expression", EXPRESSION...]],
      #       ")"],
      #     ".",
      #     ["viewExpression",
      #       "win",
      #       ":",
      #       "time",
      #       "(",
      #       ["expressionWithTimeList",
      #         ["expressionWithTimeInclLast",
      #           ["expressionWithTime",
      #             ["timePeriod",
      #               ["secondPart", ["numberconstant", ["number", "20"]], "sec"]]]]],
      #       ")"]]]],

      NON_ALIAS_NODES = ['eventFilterExpression','viewExpression','.','unidirectional','retain-union','retain-intersection']

      def targets
        [ self.find('eventFilterExpression').find('classIdentifier').find('escapableStr').child.name ]
      end

      def aliases
        alias_nodes = children.select{|n| not NON_ALIAS_NODES.include?(n.name) }
        if alias_nodes.size == 2
          if alias_nodes[0].name =~ /^as$/i
            [ [ alias_nodes[1].name, self.targets.first ] ]
          else
            raise "unexpected FROM clause (non-AS for alias pattern): #{alias_nodes.map(&:name).join(',')}"
          end
        elsif alias_nodes.size == 0
          []
        else # 1 or 3 or more
          raise "unexpected FROM clause (non-AS for alias pattern): #{alias_nodes.map(&:name).join(',')}"
        end
      end

      def fields(default_target=nil, known_targets_aliases=[])
        this_target = self.targets.first
        self.listup(:prop).map{|p| p.fields(this_target, known_targets_aliases)}.reduce(&:+) || []
      end
    end

    class ASTStreamPatternNode < ASTStreamNode
      ## MEMO: Pattern itself can have alias name, but it makes no sense. So we ignore it.
      ##       ('x' is ignored): pattern [... ] AS x
      #
      # pattern ( ex: FROM pattern[ every a=events1 -> b=Events1(name=a.name, type='T') where timer:within(1 min) ].win:time(2 hour) )
      #
      #
      # ["streamExpression",
      #   ["patternInclusionExpression",
      #     "pattern",
      #     "[",
      #     ["patternExpression",
      #       ["followedByExpression",
      #         ["orExpression", ["andExpression",
      #             ["matchUntilExpression", ["qualifyExpression",
      #                 "every",
      #                 ["guardPostFix",
      #                   ["atomicExpression",
      #                     ["patternFilterExpression", "a", "=", ["classIdentifier", ["escapableStr", "EventA"]]]]]]]]],
      #         ["followedByRepeat",
      #           "->",
      #           ["orExpression", ["andExpression",
      #               ["matchUntilExpression", ["qualifyExpression",
      #                   ["guardPostFix",
      #                     ["atomicExpression",
      #                       ["patternFilterExpression", "b", "=", ["classIdentifier", ["escapableStr", "EventA"]],
      #                         "(",
      #                         ["expressionList", ["expression", EXPRESSION...], ",", ["expression", EXPRESSION...]],
      #                         ")"],
      #                       "WHERE",
      #                       ["guardWhereExpression",
      #                         "timer",
      #                         ":",
      #                         "within",
      #                         "(",
      #                         ["expressionWithTimeList", ["expressionWithTimeInclLast", ["expressionWithTime",
      #                               ["timePeriod", ["minutePart", ["numberconstant", ["number", "1"]], "min"]]]]],
      #                         ")"]]]]]]]]],
      #       "]"]],
      #   ".",
      #   ["viewExpression",
      #     "win",
      #     ":",
      #     "time",
      #     "(",
      #     ["expressionWithTimeList", ["expressionWithTimeInclLast", ["expressionWithTime",
      #           ["timePeriod", ["hourPart", ["numberconstant", ["number", "2"]], "hour"]]]]],
      #     ")"]],
      def targets
        self.listup(:pattern).map(&:target)
      end

      def aliases
        self.listup(:pattern).map{|p| [ p.alias, p.target ] }
      end

      def fields(default_target=nil, known_targets_aliases=[])
        self.listup(:pattern).map{|p| p.fields(default_target, known_targets_aliases) }.reduce(&:+) || []
      end
    end

    class ASTPatternNode < ASTNode
      # ["patternFilterExpression", "a", "=", ["classIdentifier", ["escapableStr", "EventA"]]]

      # ["patternFilterExpression", "b", "=", ["classIdentifier", ["escapableStr", "EventA"]],
      #   "(",
      #   ["expressionList", ["expression", EXPRESSION...], ",", ["expression", EXPRESSION...]],
      #   ")"]

      def nodetype?(*sym)
        sym.include?(:pattern)
      end

      def target
        self.find('classIdentifier').find('escapableStr').child.name
      end

      def alias
        @children[0].name
      end

      def fields(default_target=nil, known_targets_aliases=[])
        this_target = self.target
        self.listup(:prop).map{|p| p.fields(this_target, known_targets_aliases) }.reduce(&:+) || []
      end
    end

    class ASTSubSelectNode < ASTNode
      # ["startEPLExpressionRule",
      #   ["eplExpression",
      #     ["selectExpr",
      #       "select",
      #       ["selectClause", ["selectionList", ["selectionListElement", "*"]]],
      #       "from",
      #       ["fromClause",
      #         ["streamExpression", ["eventFilterExpression", ["classIdentifier", ["escapableStr", "RfidEvent"]]], "as", "RFID"],
      #         "regularJoin"],
      #       "where",
      #       ["whereClause",
      #         ["evalOrExpression", ["evalAndExpression", ["bitWiseExpression", ["negatedExpression",
      #                 ["evalEqualsExpression", ["evalRelationalExpression", ["concatenationExpr", ["additiveExpression",
      #                         ["multiplyExpression", ["unaryExpression",
      #                             ["constant", ["stringconstant", "\"Dock 1\""]]]]]]],
      #                   "=",
      #                   ["evalRelationalExpression",
      #                     ["concatenationExpr", ["additiveExpression", ["multiplyExpression", ["unaryExpression",
      #                             ["rowSubSelectExpression",
      #                               ["subQueryExpr",
      #                                 "(",
      #                                 "select",
      #                                 ["selectionList",
      #                                   ["selectionListElement",
      #                                     ["selectionListElementExpr",
      #                                       ["expression", EXPRESSION...]]]],
      #                                 "from",
      #                                 ["subSelectFilterExpr",
      #                                   ["eventFilterExpression", ["classIdentifier", ["escapableStr", "Zones"]]],
      #                                   ".",
      #                                   ["viewExpression",
      #                                     "std",
      #                                     ":",
      #                                     "unique",
      #                                     "(",
      #                                     ["expressionWithTimeList",
      #                                       ["expressionWithTimeInclLast",
      #                                         ["expressionWithTime",
      #                                           ["expressionQualifyable",
      #                                             ["expression", EXPRESSION...]]]]],
      #                                     ")"]],
      #                                 "where",
      #                                 ["whereClause", ...],
      #                                 ")"]]]]]]]]]]]]]]],
      #   "<EOF>"]

      def nodetype?(*sym)
        sym.include?(:subquery)
      end
    end

    def self.imported_java_class?(name)
      return false unless name =~ /^[A-Z]/
      # Esper auto-imports the following Java library packages:
      # java.lang.* -> Java::JavaLang::*
      # java.math.* -> Java::JavaMath::*
      # java.text.* -> Java::JavaText::*
      # java.util.* -> Java::JavaUtil::*
      java_class('Java::JavaLang::'+name) || java_class('Java::JavaMath::'+name) ||
        java_class('Java::JavaText::'+name) || java_class('Java::JavaUtil::'+name) || false
    end

    def self.java_class(const_name)
      begin
        c = eval(const_name)
        c.class == Kernel ? nil : c
      rescue NameError
        return nil
      end
    end
  end
end
