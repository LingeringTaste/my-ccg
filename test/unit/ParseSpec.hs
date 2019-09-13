-- Copyright China University of Water Resources and Electric Power (c) 2019
-- All rights reserved.

module ParseSpec where

import Category
import Rule
import Parse
import Test.Hspec

spec :: Spec
spec = do
  describe "Parse" $ do
    it "The result of initPhraCate [] is []" $ do
      initPhraCate [] `shouldBe` ([] :: [PhraCate])

    it "The result of initPhraCate [s] is [((0,0),[(s,\"Desig\")],0)]" $ do
      initPhraCate [sCate] `shouldBe` ([((0,0),[(sCate, "Desig")],0)] :: [PhraCate])

    it "The result of initPhraCate [np, (s\\.np)/.np, np] is [((0,0),[(np,\"Desig\")],0),((1,0),[((s\\.np)/.np,\"Desig\")],1),((2,0),[(np,\"Desig\")],2)]" $ do
      let c1 = npCate
      let c2 = getCateFromString "(s\\.np)/.np"
      let c3 = npCate
      initPhraCate [c1,c2,c3] `shouldBe` ([((0,0),[(c1, "Desig")],0),((1,0),[(c2, "Desig")],1),((2,0),[(c3,"Desig")],2)] :: [PhraCate])

    it "The result of createPhraCate 0 1 s \"Np/s\" 1 is ((0,1),[(s, \"Np/s\")],1)" $ do
      let c = sCate
      createPhraCate 0 1 c "Np/s" 1 `shouldBe` (((0,1),[(c,"Np/s")],1)::PhraCate)

    it "The result of applying func pclt to ((0,0),[(np,\"Desig\")],0) and ((1,0),[((s\\.np)/.np,\"Desig\")],1) is True" $ do
      let c1 = npCate
      let c2 = getCateFromString "(s\\.np)/.np"
      let pcs = initPhraCate [c1, c2]
      let pc1 = head pcs
      let pc2 = last pcs
      pclt pc1 pc2 `shouldBe` (True :: Bool)

    it "The result of applying func pclt to ((0,0),[(np,\"Desig\")],0) and ((0,0),[(s/.np, \"Desig\")],0) is False" $ do
      let c1 = npCate
      let c2 = getCateFromString "s/.np"
      let pcs1 = initPhraCate [c1]
      let pc1 = head pcs1
      let pcs2 = initPhraCate [c2]
      let pc2 = head pcs2
      pclt pc1 pc2 `shouldBe` (False :: Bool)

    it "The result of stOfCate ((1,0),[(s\\.np,\"Desig\")],1) is 1" $ do
      let c = getCateFromString "s\\.np"
      let pc = createPhraCate 1 0 c "Desig" 1
      stOfCate pc `shouldBe` 1

    it "The result of spOfCate ((1,0),[(s\\.np, \"Desig\")],1) is 0" $ do
      let c = getCateFromString "s\\.np"
      let pc = createPhraCate 1 0 c "Desig" 1
      spOfCate pc `shouldBe` 0

    it "The result of ssOfCate ((1,0),[(s\\.np, \"Desig\")],1) is 1" $ do
      let c = getCateFromString "s\\.np"
      let pc = createPhraCate 1 0 c "Desig" 1
      ssOfCate pc `shouldBe` 1

    it "The result of ctOfCate ((1,0),[(s\\.np, \"Desig\")],1) is [(s\\.np, \"Desig\")]" $ do
      let c = getCateFromString "s\\.np"
      let pc = createPhraCate 1 0 c "Desig" 1
      ctOfCate pc `shouldBe` [(c,"Desig")]

    it "The result of caOfCate ((1,0),[(s\\.np, \"Desig\")],1) is [s\\.np]" $ do
      let c = getCateFromString "s\\.np"
      let pc = createPhraCate 1 0 c "Desig" 1
      caOfCate pc `shouldBe` [c]
   
    it "The result of cateComb ((0,0),[(np, \"Desig\")],0) ((1,0),[(s\\.np, \"Desig\")],1) is ((0,1),[(s, \"<\")],1)" $ do
      let c1 = npCate
      let c2 = getCateFromString "s\\.np"
      let c3 = sCate
      let pc1 = createPhraCate 0 0 c1 "Desig" 0
      let pc2 = createPhraCate 1 0 c2 "Desig" 1
      let pc3 = createPhraCate 0 1 c3 "<" 1
      cateComb pc1 pc2 `shouldBe` pc3

    it "The result of cateComb ((0,0),[(np, \"Desig\")],0) ((1,0),[(s\\.np,\"Desig\")],1) is NOT ((0,1),[(np,\"Desig\"],1)" $ do
      let c1 = npCate
      let c2 = getCateFromString "s\\.np"
      let c3 = npCate
      let pc1 = createPhraCate 0 0 c1 "Desig" 0
      let pc2 = createPhraCate 1 0 c2 "Desig" 1
      let pc3 = createPhraCate 0 1 c3 "Desig" 1
      cateComb pc1 pc2 /= pc3

    it "The result of cateComb ((0,0),[(np,\"Desig\")],0) ((1,0),[((s\\.np)/.np,\"Desig\")],1) is ((0,1),[(s/.np,\">T->B\")],1)" $ do
      let c1 = npCate
      let c2 = getCateFromString "(s\\.np)/.np"
      let c3 = getCateFromString "s/.np"
      let pc1 = createPhraCate 0 0 c1 "Desig" 0
      let pc2 = createPhraCate 1 0 c2 "Desig" 1
      let pc3 = createPhraCate 0 1 c3 ">T->B" 1
      cateComb pc1 pc2 `shouldBe` pc3

    it "The result of cateComb ((0,0),[(s,\"Desig\")],0) ((1,0),[(s\\.np,\"Desig\")],1) is ((0,1),[(s,\"Np/s-<\")],1)" $ do
      let c1 = sCate
      let c2 = getCateFromString "s\\.np"
      let c3 = sCate
      let pc1 = createPhraCate 0 0 c1 "Desig" 0
      let pc2 = createPhraCate 1 0 c2 "Desig" 1
      let pc3 = createPhraCate 0 1 c3 "Np/s-<" 1
      cateComb pc1 pc2 `shouldBe` pc3
    
    it "The result of cateComb ((0,0),[((s\\.np)/.np,\"Desig\")],0) ((1,0),[(s,\"Desig\")],1) is ((0,1),[(s\\.np,\"Np/s->\")],1)" $ do
      let c1 = getCateFromString "(s\\.np)/.np"
      let c2 = sCate
      let c3 = getCateFromString "s\\.np"
      let pc1 = createPhraCate 0 0 c1 "Desig" 0
      let pc2 = createPhraCate 1 0 c2 "Desig" 1
      let pc3 = createPhraCate 0 1 c3 "Np/s->" 1
      cateComb pc1 pc2 `shouldBe` pc3
    
    it "The result of getNuOfInputCates ((0,0),[(np,\"Desig\")],0) ((1,0),[((s\\.np)/.np,\"Desig\")],1) ((0,1),[(s/.np,\"<\")],1) is 2" $ do
      let c1 = npCate
      let c2 = getCateFromString "(s\\.np)/.np"
      let c3 = getCateFromString "s/.np"
      let pc1 = createPhraCate 0 0 c1 "Desig" 0
      let pc2 = createPhraCate 1 0 c2 "Desig" 1
      let pc3 = createPhraCate 0 1 c3 "<" 1
      let pcs = [pc1,pc2,pc3]
      getNuOfInputCates pcs `shouldBe` 2

    it "The result of parse [((0,0),[(np,\"Desig\")],0), ((1,0),[((s\\.np)/.np,\"Desig\")],1)] is [((0,0),[(np,\"Desig\")],0), ((1,0),[(s\\.np)/.np,\"Desig\")],1), ((0,1),[(s/.np,\">T->B\")],1)]" $ do
      let c1 = npCate
      let c2 = getCateFromString "(s\\.np)/.np"
      let c3 = getCateFromString "s/.np"
      let pc1 = createPhraCate 0 0 c1 "Desig" 0
      let pc2 = createPhraCate 1 0 c2 "Desig" 1
      let pc3 = createPhraCate 0 1 c3 ">T->B" 1
      let pcs = [pc1,pc2]
      let pcClo = pcs ++ [pc3]
      parse pcs `shouldBe` pcClo

    it "The result of parse [((0,0),[(np,\"Desig\")],0), ((1,0),[((s\\.np)/.np,\"Desig\")],1), ((2,0),[(np,\"Desig\")],2)] is [((0,0),[(np,\"Desig\")],0), ((1,0),[((s\\.np)/.np,\"Desig\")],1), ((2,0),[(np,\"Desig\")],2), ((0,1),[(s/.np,\">T->B\")],1), ((1,1),[(s\\.np,\">\")],2), ((0,2),[(s,\"<\")],1), ((0,2),[(s,\">\")],2)], without considering element order." $ do
      let c01 = npCate
      let c02 = getCateFromString "(s\\.np)/.np"
      let c03 = npCate
      let c11 = getCateFromString "s/.np"
      let c12 = getCateFromString "s\\.np"
      let c2 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">T->B" 1
      let pc12 = createPhraCate 1 1 c12 ">" 2
      let pc21 = createPhraCate 0 2 c2 "<" 1
      let pc22 = createPhraCate 0 2 c2 ">" 2 
      let pcs = [pc01,pc02,pc03]
      let pcClo = pcs ++ [pc11,pc12,pc21,pc22]
      parse pcs `shouldBe` pcClo

    it "The result of parse [((0,0),[(np/.np,\"Desig\")],0), ((1,0),[(np,\"Desig\")],1), ((2,0),[(s\\*np,\"Desig\")],2)] is [((0,0),[(np/.np,\"Desig\")],0), ((1,0),[(np,\"Desig\")],1), ((2,0),[(s\\*np,\"Desig\")],2), ((0,1),[(np,\">\")],1), ((1,1),[(s,\"<\")],2), ((0,2),[],1), ((0,2),[(s,\"<\")],2)], without considering element order." $ do
      let c01 = getCateFromString "np/.np"
      let c02 = npCate
      let c03 = getCateFromString "s\\*np"
      let c11 = npCate
      let c12 = sCate
      let c21 = npCate
      let c22 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">" 1
      let pc12 = createPhraCate 1 1 c12 "<" 2
      let pc21 = createPhraCate 0 2 c21 "Np/s->" 1
      let pc22 = createPhraCate 0 2 c22 "<" 2 
      let pcs = [pc01,pc02,pc03]
      let pcClo = pcs ++ [pc11,pc12,pc21,pc22]
      parse pcs `shouldBe` pcClo

    it "The result of findCate （0,-1) [((0,0),[(np,\"Desig\")],0), ((1,0),[(s\\.np,\"Desig\")],1)] is []" $ do
      let c1 = npCate
      let c2 = getCateFromString "s\\.np"
      findCate (0,-1) [((0,0),[(c1,"Desig")],0), ((1,0),[(c2,"Desig")],1)] `shouldBe` []

    it "The result of findCate （0,0) [((0,0),[(np,\"Desig\")],0), ((1,0),[(s\\.np,\"Desig\")],1)] is ((0,0),[(np,\"Desig\")],0)" $ do
      let c1 = npCate
      let c2 = getCateFromString "s\\.np"
      let pc1 = createPhraCate 0 0 c1 "Desig" 0
      let pc2 = createPhraCate 1 0 c2 "Desig" 1
      findCate (0,0) [pc1, pc2] `shouldBe` [pc1]

    it "The result of findSplitCate ((0,2),[(s,\"<\")],2) [((0,0),[(np/.np,\"Desig\")],0), ((1,0),[(np,\"Desig\")],1), ((2,0),[(s\\*np,\"Desig\")],2), ((0,1),[(np,\">\")],1), ((1,1),[(s,\"<\")],2), ((0,2),[],1), ((0,2),[(s,\"<\")],2)] is [((0,1),[(np,\">\")],1), (2,0),[(s,\"Desig\")],2)]" $ do
      let c01 = getCateFromString "np/.np"
      let c02 = npCate
      let c03 = getCateFromString "s\\*np"
      let c11 = npCate
      let c12 = sCate
      let c21 = nilCate
      let c22 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">" 1
      let pc12 = createPhraCate 1 1 c12 "<" 2
      let pc21 = createPhraCate 0 2 c21 "Nil" 1
      let pc22 = createPhraCate 0 2 c22 "<" 2 
      let pcs = [pc01,pc02,pc03]
      let pcClo = pcs ++ [pc11,pc12,pc21,pc22]
      findSplitCate pc22 pcClo `shouldBe` [(pc11,pc03)]

    it "The result of findSplitCate ((1,1),[(s,\"<\")],2) [((0,0),[(np/.np,\"Desig\")],0), ((1,0),[(np,\"Desig\")],1), ((2,0),[(s\\*np,\"Desig\")],2), ((0,1),[(np,\">\")],1), ((1,1),[(s,\"<\")],2), ((0,2),[],1), ((0,2),[(s,\"<\")],2)] is [((1,0),[(np,\"Desig\")],1), (2,0),[(s,\"Desig\")],2)]" $ do
      let c01 = getCateFromString "np/.np"
      let c02 = npCate
      let c03 = getCateFromString "s\\*np"
      let c11 = npCate
      let c12 = sCate
      let c21 = nilCate
      let c22 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">" 1
      let pc12 = createPhraCate 1 1 c12 "<" 2
      let pc21 = createPhraCate 0 2 c21 "Nil" 1
      let pc22 = createPhraCate 0 2 c22 "<" 2 
      let pcs = [pc01,pc02,pc03]
      let pcClo = pcs ++ [pc11,pc12,pc21,pc22]
      findSplitCate pc12 pcClo `shouldBe` [(pc02,pc03)]

    it "The result of findTipsOfTree [((1,1),[(s,\"<\")],2)] [((0,0),[(np/.np,\"Desig\")],0), ((1,0),[(np,\"Desig\")],1), ((2,0),[(s\\*np,\"Desig\")],2), ((0,1),[(np,\">\")],1), ((1,1),[(s,\"<\")],2), ((0,2),[],1), ((0,2),[(s,\"<\")],2)] is [((1,1),[(s,\"<\")],2)]" $ do
      let c01 = getCateFromString "np/.np"
      let c02 = npCate
      let c03 = getCateFromString "s\\*np"
      let c11 = npCate
      let c12 = sCate
      let c21 = nilCate
      let c22 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">" 1
      let pc12 = createPhraCate 1 1 c12 "<" 2
      let pc21 = createPhraCate 0 2 c21 "Nil" 1
      let pc22 = createPhraCate 0 2 c22 "<" 2 
      let pcs = [pc01,pc02,pc03]
      let pcClo = pcs ++ [pc11,pc12,pc21,pc22]
      findTipsOfTree [pc12] pcClo `shouldBe` [pc12]

    it "The result of findTipsOfTree [((0,2),[(s,\"<\")],2),((0,1),[(np,\">\")],1),((2,0),[(s\\*np,\"Desig\")],2)] [((0,0),[(np/.np,\"Desig\")],0), ((1,0),[(np,\"Desig\")],1), ((2,0),[(s\\*np,\"Desig\")],2), ((0,1),[(np,\">\")],1), ((1,1),[(s,\"<\")],2), ((0,2),[],1), ((0,2),[(s,\"<\")],2)] is [((0,1),[(np,\">\")],1)]" $ do
      let c01 = getCateFromString "np/.np"
      let c02 = npCate
      let c03 = getCateFromString "s\\*np"
      let c11 = npCate
      let c12 = sCate
      let c21 = nilCate
      let c22 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">" 1
      let pc12 = createPhraCate 1 1 c12 "<" 2
      let pc21 = createPhraCate 0 2 c21 "Nil" 1
      let pc22 = createPhraCate 0 2 c22 "<" 2 
      let pcs = [pc01,pc02,pc03]
      let pcClo = pcs ++ [pc11,pc12,pc21,pc22]
      findTipsOfTree [pc22,pc11,pc03] pcClo `shouldBe` [pc11]

    it "The result of findCateBySpan 1 [((0,0),[(np/.np,\"Desig\")],0), ((1,0),[(np,\"Desig\")],1), ((2,0),[(s\\*np,\"Desig\")],2), ((0,1),[(np,\">\")],1), ((1,1),[(s,\"<\")],2), ((0,2),[],1), ((0,2),[(s,\"<\")],2)] is [((0,1),[(np,\">\")],1), ((1,1),[(s, \"<\")],2)]" $ do
      let c01 = getCateFromString "np/.np"
      let c02 = npCate
      let c03 = getCateFromString "s\\*np"
      let c11 = npCate
      let c12 = sCate
      let c21 = nilCate
      let c22 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">" 1
      let pc12 = createPhraCate 1 1 c12 "<" 2
      let pc21 = createPhraCate 0 2 c21 "Nil" 1
      let pc22 = createPhraCate 0 2 c22 "<" 2 
      let pcs = [pc01,pc02,pc03]
      let pcClo = pcs ++ [pc11,pc12,pc21,pc22]
      findCateBySpan 1 pcClo `shouldBe` [pc11,pc12]

    it "The result of findCateBySpan 0 [((0,0),[(np/.np,\"Desig\")],0), ((1,0),[(np,\"Desig\")],1), ((2,0),[(s\\*np,\"Desig\")],2), ((0,1),[(np,\">\")],1), ((1,1),[(s,\"<\")],2), ((0,2),[],1), ((0,2),[(s,\"<\")],2)] is [((0,0),[(np/.np, \"Desig\")],0), ((1,0),[(np,\"Desig\")],1), ((2,0),[(s, \"Desig\")],2)]" $ do
      let c01 = getCateFromString "np/.np"
      let c02 = npCate
      let c03 = getCateFromString "s\\*np"
      let c11 = npCate
      let c12 = sCate
      let c21 = nilCate
      let c22 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">" 1
      let pc12 = createPhraCate 1 1 c12 "<" 2
      let pc21 = createPhraCate 0 2 c21 "Nil" 1
      let pc22 = createPhraCate 0 2 c22 "<" 2 
      let pcs = [pc01,pc02,pc03]
      let pcClo = pcs ++ [pc11,pc12,pc21,pc22]
      findCateBySpan 0 pcClo `shouldBe` [pc01,pc02,pc03]

    it "The result of findCateBySpan 2 [((0,0),[(np/.np,\"Desig\")],0), ((1,0),[(np,\"Desig\")],1), ((2,0),[(s\\*np,\"Desig\")],2), ((0,1),[(np,\">\")],1), ((1,1),[(s,\"<\")],2), ((0,2),[],1), ((0,2),[(s,\"<\")],2)] is [((0,2),[],1), ((0,2),[(s, \"<\")],2)]" $ do
      let c01 = getCateFromString "np/.np"
      let c02 = npCate
      let c03 = getCateFromString "s\\*np"
      let c11 = npCate
      let c12 = sCate
      let c21 = nilCate
      let c22 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">" 1
      let pc12 = createPhraCate 1 1 c12 "<" 2
      let pc21 = createPhraCate 0 2 c21 "Nil" 1
      let pc22 = createPhraCate 0 2 c22 "<" 2 
      let pcs = [pc01,pc02,pc03]
      let pcClo = pcs ++ [pc11,pc12,pc21,pc22]
      findCateBySpan 2 pcClo `shouldBe` [pc21,pc22]

    it "The result of divPhraCateBySpan [((0,0),[(np/.np,\"Desig\")],0), ((1,0),[(np,\"Desig\")],1), ((2,0),[(s\\*np,\"Desig\")],2), ((0,1),[(np,\">\")],1), ((1,1),[(s,\"<\")],2), ((0,2),[],1), ((0,2),[(s,\"<\")],2)] is [[((0,0),[(np/.np, \"Desig\")],0), ((1,0),[(np,\"Desig\")],1), ((2,0),[(s\\*np, \"Desig\")],2)], [((0,1),[(np, \">\")],1), ((1,1),[(s, \"<\")],2)], [((0,2),[(s, \"<\")],2)]]" $ do
      let c01 = getCateFromString "np/.np"
      let c02 = npCate
      let c03 = getCateFromString "s\\*np"
      let c11 = npCate
      let c12 = sCate
      let c21 = nilCate
      let c22 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">" 1
      let pc12 = createPhraCate 1 1 c12 "<" 2
      let pc21 = createPhraCate 0 2 c21 "Nil" 1
      let pc22 = createPhraCate 0 2 c22 "<" 2 
      let pcClo = [pc01,pc11,pc22,pc02,pc12,pc03]
      divPhraCateBySpan pcClo `shouldBe` [[pc01,pc02,pc03],[pc11,pc12],[pc22]]

    it "The result of growTree [((0,2),[(s, \">\")],2)] [((0,0),[(np, \"Desig\")],0), ((1,0),[(s\\.np, \"Desig\")],1), ((2,0),[(np, \"Desig\")],2), ((0,1),[(s/.np,\">T->B\")],1), ((1,1),[(s\\.np, \"<\")],2), ((0,2),[(s, \"<\")],1), ((0,2),[(s, \">\")],2) is [((0,0),[(np, \"Desig\")],0), ((1,0),[((s\\.np)/.np, \"Desig\")],1), ((0,1),[(s/.np, \">T->B\")],1), ((2,0),[(np, \"Desig\")],2), ((0,2),[(s, \">\")],2)]" $ do
      let c01 = npCate
      let c02 = getCateFromString "s\\.np/.np"
      let c03 = npCate
      let c11 = getCateFromString "s/.np"
      let c12 = getCateFromString "s\\.np"
      let c21 = sCate
      let c22 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">" 1
      let pc12 = createPhraCate 1 1 c12 "<" 2
      let pc21 = createPhraCate 0 2 c21 "<" 1
      let pc22 = createPhraCate 0 2 c22 ">" 2 
      let pcClo = [pc01,pc02,pc03,pc11,pc12,pc21,pc22]
      growTree [pc22] pcClo `shouldBe` [[pc01,pc02,pc11,pc03,pc22]]

    it "The result of growTree [((0,2),[(s, \"<\")],1)]  [((0,0),[(np, \"Desig\")],0), ((1,0),[(s\\.np, \"Desig\")],1), ((2,0),[(np, \"Desig\")],2), ((0,1),[(s/.np,\">T->B\")],1), ((1,1),[(s\\.np, \"<\")],2), ((0,2),[(s, \"<\")],1), ((0,2),[(s, \">\")],2) is [((1,0),[(s\\.np/.np, \"Desig\")],1), ((2,0),[(np, \"Desig\")],2), ((0,0),[(np, \"Desig\")],0), ((1,1),[(s\\.np, \">\")],2), ((0,2),[(s, \"<\")],1)]" $ do
      let c01 = npCate
      let c02 = getCateFromString "s\\.np/.np"
      let c03 = npCate
      let c11 = getCateFromString "s/.np"
      let c12 = getCateFromString "s\\.np"
      let c21 = sCate
      let c22 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">T->B" 1
      let pc12 = createPhraCate 1 1 c12 "<" 2
      let pc21 = createPhraCate 0 2 c21 "<" 1
      let pc22 = createPhraCate 0 2 c22 ">" 2 
      let pcClo = [pc01,pc02,pc03,pc11,pc12,pc21,pc22]
      growTree [pc21] pcClo `shouldBe` [[pc02,pc03,pc01,pc12,pc21]]

    it "The result of growForest [[((0,2),[(s, \"<\")],1)], [((0,2),[(s, \">\")],2)]] [((0,2),[s],2)] [((0,0),[(np, \"Desig\")],0), ((1,0),[(s\\.np, \"Desig\")],1), ((2,0),[(np, \"Desig\")],2), ((0,1),[(s/.np,\">T->B\")],1), ((1,1),[(s\\.np, \"<\")],2), ((0,2),[(s, \"<\")],1), ((0,2),[(s, \">\")],2) is [[((1,0),[(s\\.np/.np, \"Desig\")],1), ((2,0),[(np, \"Desig\")],2), ((0,0),[(np, \"Desig\")],0), ((1,1),[(s\\.np, \">\")],2), ((0,2),[(s, \"<\")],1)], [((0,0),[(np, \"Desig\")],0), ((1,0),[((s\\.np)/.np, \"Desig\")],1), ((0,1),[(s/.np, \">T->B\")],1), ((2,0),[(np, \"Desig\")],2), ((0,2),[(s, \">\")],2)]]" $ do
      let c01 = npCate
      let c02 = getCateFromString "s\\.np/.np"
      let c03 = npCate
      let c11 = getCateFromString "s/.np"
      let c12 = getCateFromString "s\\.np"
      let c21 = sCate
      let c22 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">T->B" 1
      let pc12 = createPhraCate 1 1 c12 "<" 2
      let pc21 = createPhraCate 0 2 c21 "<" 1
      let pc22 = createPhraCate 0 2 c22 ">" 2
      let pcClo = [pc01,pc02,pc03,pc11,pc12,pc21,pc22]
      growForest [[pc21],[pc22]] pcClo `shouldBe` [[pc02,pc03,pc01,pc12,pc21],[pc01,pc02,pc11,pc03,pc22]]

    it "The result of growForest [[((0,2),[],1)], [((0,2),[(s, \"<\")],2)] [((0,0),[(np/.np, \"Desig\")],0), ((1,0),[(np, \"Desig\")],1), ((2,0),[(s\\*np, \"Desig\")],2), ((0,1),[(np, \">\")],1), ((1,1),[(s, \"<\")],2), ((0,2),[],1), ((0,2),[(s, \"<\")],2) is [[((1,0),[(np, \"Desig\")],1), ((2,0),[(s\\*np, \"Desig\")],2), ((0,0),[(np/.np, \"Desig\")],0), ((1,1),[(s, \"<\")],2), ((0,2),[],1)], [((0,0),[(np/.np, \"Desig\")],0), ((1,0),[(np, \"Desig\")],1), ((0,1),[(np, \">\")],1), ((2,0),[(s\\*np, \"Desig\")],2), ((0,2),[(s, \"<\")],2)" $ do
      let c01 = getCateFromString "np/.np"
      let c02 = npCate
      let c03 = getCateFromString "s\\*np"
      let c11 = npCate
      let c12 = sCate
      let c21 = nilCate
      let c22 = sCate
      let pc01 = createPhraCate 0 0 c01 "Desig" 0
      let pc02 = createPhraCate 1 0 c02 "Desig" 1
      let pc03 = createPhraCate 2 0 c03 "Desig" 2
      let pc11 = createPhraCate 0 1 c11 ">" 1
      let pc12 = createPhraCate 1 1 c12 "<" 2
      let pc21 = createPhraCate 0 2 c21 "Nil" 1
      let pc22 = createPhraCate 0 2 c22 "<" 2 
      let pcClo = [pc01,pc02,pc03,pc11,pc12,pc21,pc22]
      growForest [[pc21],[pc22]] pcClo `shouldBe` [[pc02,pc03,pc01,pc12,pc21],[pc01,pc02,pc11,pc03,pc22]]


