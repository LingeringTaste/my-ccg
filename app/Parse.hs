-- Copyright China University of Water Resources and Electric Power (c) 2019
-- All rights reserved.

module Parse (
    Start,         -- Int
    Span,          -- Int
    SecStart,      -- Int
    PhraCate,      -- ((Start, Span), [(Category, Tag, Seman)], SecStart)
    pclt,          -- PhraCate -> PhraCate -> Bool
    stOfCate,      -- PhraCate -> Start
    spOfCate,      -- PhraCate -> Span
    ctsOfCate,     -- PhraCate -> [(Category, Tag, Seman)]
    caOfCate,      -- PhraCate -> [Category]
    taOfCate,      -- PhraCate -> [String]
    seOfCate,      -- PhraCate -> [Seman]
    csOfCate,      -- PhraCate -> [(Category, Seman)]
    ssOfCate,      -- PhraCate -> SecStart
    cateComb,      -- PhraCate -> PhraCate -> [PhraCate]
    initPhraCate,  -- [(Category, Seman)] -> [PhraCate]
    createPhraCate,-- Start -> Span -> Category -> Tag -> Seman -> SecStart -> PhraCate
    parse,         -- [PhraCate] -> [PhraCate]
    getNuOfInputCates,       -- [PhraCate] -> Int 
    growForest,              -- [[PhraCate]] -> [PhraCate] -> [[PhraCate]]
    growTree,      -- [PhraCate] -> [PhraCate] -> [[PhraCate]]
    findCate,                -- (Int, Int) -> [PhraCate] -> [PhraCate]
    findSplitCate,           -- PhraCate -> [PhraCate] -> [PhraCate]
    findTipsOfTree,          -- [PhraCate] -> [PhraCate] -> [PhraCate]
    findCateBySpan,          -- Int -> [PhraCate] -> [PhraCate]
    divPhraCateBySpan,       -- [PhraCate] -> [[PhraCate]]
    quickSort                -- [PhraCate] -> [PhraCate]
    ) where

import Data.Tuple.Utils
import Category
import Rule

type Start = Int         -- The start position of a phrase (category) in sentences.
type Span = Int          -- The span distance of a phrase (category) in sentences.
type SecStart = Int      -- The position of spliting a phrase (category).

-- When combining two phrase categories, there might be more than one rule available, resulting in multiple categories (Usually the resultant categories are same).

type PhraCate = ((Start, Span), [(Category, Tag, Seman)], SecStart)

-- Define relation 'less than' for two phrasal categories.
pclt :: PhraCate -> PhraCate -> Bool
pclt x y = (stx < sty) || ((stx == sty) && (spx < spy))
    where
    stx = stOfCate x
    sty = stOfCate y
    spx = spOfCate x
    spy = spOfCate y

-- The following functions are used to select an element from tuple PhraCate.
stOfCate :: PhraCate -> Start
stOfCate (s, _, _) = fst s

spOfCate :: PhraCate -> Span
spOfCate (s, _, _) = snd s

ctsOfCate :: PhraCate -> [(Category, Tag, Seman)]
ctsOfCate (_, cts, _) = cts

caOfCate :: PhraCate -> [Category]
caOfCate pc = [fst3 c | c <- cts]
    where
    cts = ctsOfCate pc

taOfCate :: PhraCate -> [Tag]
taOfCate pc = [snd3 c | c <- cts]
    where
    cts = ctsOfCate pc

seOfCate :: PhraCate -> [Seman]
seOfCate pc = [thd3 c | c <- cts]
    where
    cts = ctsOfCate pc

csOfCate :: PhraCate -> [(Category, Seman)]
csOfCate pc = zip (caOfCate pc) (seOfCate pc)

ssOfCate :: PhraCate -> SecStart
ssOfCate (_, _, s) = s

-- Function cateComb combines two input (phrasal) categories into one result.
-- The two input categories satisfies concatenative requirements, and may have multiple resultant categories when multiple rules are available.
-- Here phrasal categories are still modelled by list. After introduing categorial conversion for Chinese structure overlapping, there may be more than one category.
-- Results ((-1,-1),[],-1) and ((x,y),[],z) respectively denote concatenative failure and no rule available.

cateComb :: PhraCate -> PhraCate -> PhraCate
cateComb pc1 pc2
    | st1 + sp1 + 1 /= st2 = ((-1,-1),[],-1)
    | otherwise = ((st1, sp1 + sp2 + 1), rcs, st2)
    where
    st1 = stOfCate pc1   -- Start position of pc1
    sp1 = spOfCate pc1   -- Span of pc1
    st2 = stOfCate pc2   -- Start position of pc2
    sp2 = spOfCate pc2   -- Span of pc2
    cs1 = [(fst3 cts, thd3 cts)| cts <- ctsOfCate pc1]   -- [Category, Seman]
    cs2 = [(fst3 cts, thd3 cts)| cts <- ctsOfCate pc2]   -- [Category, Seman]
    cateS1 = [(npCate, snd cs) | cs <- cs1, fst cs == sCate]     -- [(npCate, Seman)]
    cateS2 = [(npCate, snd cs) | cs <- cs2, fst cs == sCate]     -- [(npCate, Seman)]

-- Categories getten by CCG standard rules.
    catesBasic = [rule cate1 cate2 | rule <- rules, cate1 <- cs1, cate2 <- cs2]
-- Categories getten by firstly converting sentence into nominal phrase, then using standard CCG rules. For each result (<category>, <tag>, <seman>), the <tag> is changed as "Np/s-"++<tag> to remember the category conversion s->Np happens before using the standard rule <tag>.
    cts = [rule cate1 cate2 | rule <- rules, cate1 <- cateS1, cate2 <- cs2] ++ [rule cate1 cate2 | rule <- rules, cate1 <- cs1, cate2 <- cateS2]
    catesBysToNp = [(fst3 cate, "Np/s-" ++ snd3 cate, thd3 cate) | cate <- cts]
    cates = catesBasic ++ catesBysToNp
    rcs = [rc | rc <- cates, (fst3 rc) /= nilCate]

-- Context-based category conversion might be human brain's mechanism for syntax parsing, similiar to Chinese phrase-centric syntactic view. In the past, a phrase usually has a sequence of categories with the first as its classical category followed by non-classical ones.
-- To suitable for two kinds of category views, Phrase category is defined as a triple, including start position, span, and a categorial list, although there is only one category in the list under category conversion.
-- To remember the parent categories, the start position of the second category is recorded. For initial word categories, their parents don't exist.

-- Words are considered as minimal phrases, thus an universal phrase category models both words and phrases.
-- Initialize the values of PhraCate for each word of a given sentence.
-- Initial categories are designated, so their tags are "Desig"
initPhraCate :: [(Category, Seman)] -> [PhraCate]
initPhraCate [] = []
initPhraCate [c] = [((0,0),[(fst c, "Desig", snd c)],0)]    -- categories start at index 0
initPhraCate (c:cs) = [((0,0),[(fst c,"Desig",snd c)],0)] ++ [(((stOfCate pc)+1, 0), ctsOfCate pc, (stOfCate pc)+1) | pc <- (initPhraCate cs)]

-- Create a phrasal category according to its specified contents.
createPhraCate :: Start -> Span -> Category -> Tag -> Seman -> SecStart -> PhraCate
createPhraCate start span c tag seman secStart
    | c == nilCate = ((start,span),[],secStart)
    | otherwise = ((start,span),[(c, tag, seman)],secStart)

-- Find the number of input categories from the closure of phrase categories.

getNuOfInputCates :: [PhraCate] -> Int
getNuOfInputCates phraCateClosure = length [pc | pc <- phraCateClosure, spOfCate pc == 0]

-- Parsing a sequence of categories is actually to generate the closure of phrase categories with categorial combinations.

parse :: [PhraCate] -> [PhraCate]
parse phraCateInput
    | phraCateInput == transition = phraCateInput
    | otherwise = parse transition
        where
        combs = [cateComb pc1 pc2 | pc1 <- phraCateInput, pc2 <- phraCateInput, pc1 /= pc2]
        cbs = [cb | cb <- combs, cb /= ((-1,-1),[],-1), elem cb phraCateInput == False]
        transition = phraCateInput ++ (cbsRemoveDup cbs)
            where
            cbsRemoveDup [] = []
            cbsRemoveDup [x] = [x]
            cbsRemoveDup (x:xs)
                | elem x xs = cbsRemoveDup xs
                | otherwise = x:(cbsRemoveDup xs)
        -- cbsRemoveDup is used to remove duplicate elements in a list.

-- Merge all possible splits into the list [SecStart] for every (Start, Span).
-- This function is obsolete. For identical (Start, Span), merging categories and merging SecStart's are terrible opertions because of losing relations between every resultant category and its parents, just like a room with many children and an another room with many pairs of parents.
--mergeSplit :: [PhraCate] -> [PhraCate]
--mergeSplit [] = []
--mergeSplit [x] = [x]
--mergeSplit (x:xs)
--    | y == ((-1-1,)[],[]) = x:(mergeSplit xs)
--    | otherwise = ((stx, spx), cax ++ [c | c <- caOfCate y, elem c cax == False], ssx ++ [ss | ss <- ssOfCate y, elem ss ssx == False]):(mergeSplit xs)
--        where
--        stx = stOfCate x
--        spx = spOfCate x
--        y = findCate (stx, spx) xs
--        cax = caOfCate x
--        ssx = ssOfCate x

-- Generate syntactic trees (forest) from the closure of phrase categories.
-- Here is a recursived forest-growing algorithm: For the input forest, 
-- (1) If it is an empty forest without any tree, an empty forest is returned;
-- (2) Otherwise, one forest is created for every tree in input forest, return the union of all created forests.
 
growForest :: [[PhraCate]] -> [PhraCate] -> [[PhraCate]]
growForest [] _ = []                    -- Empty forest
growForest (t:ts) phraCateClosure       -- nonempty forest
    = (growTree t phraCateClosure) ++ (growForest ts phraCateClosure) 

-- One tree can grow at all tips to send forth a layer of leaves. Every parsing tree in Combinatory Categorial Grammar is one binary tree, namely from every tip, only two leaces can grow out. It makes growing process complicated that there might be more than one pair of leaves to grow out for every tip, Selecting different pairs would create different trees.
-- The forest growing from a tree is done by the following:
-- (1) Find all tips able to send forth leaves (The tips for initial categoies are no longer to grow);
-- (2) For every such tip, find all splits (namely all pairs of leaves), and create a forest, of which every tree include the input tree and a distinc pair of leaves;
-- (3) Based on merging two forests, all forests are merged into one forest. 
growTree :: [PhraCate] -> [PhraCate] -> [[PhraCate]]
growTree t phraCateClosure
    | findTipsOfTree t phraCateClosure == [] = [t]      -- No tip can grow.
    | [t] == gf = [t]                                   -- Not grow.
    | otherwise = growForest gf phraCateClosure
        where
        splOfAllTips = [findSplitCate tip phraCateClosure | tip <- (findTipsOfTree t phraCateClosure)]   -- [[(PhraCate, PhraCate)]]
        forestByTipGrow = [map (\x -> [fst x | elem (fst x) t == False] ++ [snd x | elem (snd x) t == False] ++ t ) splOfATip | splOfATip <- splOfAllTips]
        gf = uniForest forestByTipGrow

-- By growing at each tip, a tree grows and might become multiple trees because more than one split exists. 
-- Suppose tree t becomes ti = [ti1,ti2,...tin] by growing at No.i tip, and tj = [tj1,tj2,...tjm] by growing at No.j tip. Both the two forests are from the same tree t, and should merge into forest tk, tk = ti X tj. Merging tix and tjy, x<-[1..n], y<-[1..m], is actually to do an union operation on two sets.

uniForest :: [[[PhraCate]]] -> [[PhraCate]]
uniForest [] = []                -- No forest
uniForest [f] = f                -- Just one forest
uniForest (f:fs)                 -- At least two forests
    = uniForest ((uniTwoForest f (head fs)):(tail fs)) 

-- Merging two forest.
uniTwoForest :: [[PhraCate]] -> [[PhraCate]] -> [[PhraCate]]
uniTwoForest f1 f2 = [uniTwoTree t1 t2 | t1<-f1, t2<-f2]

-- Merging two trees.
uniTwoTree :: [PhraCate] -> [PhraCate] -> [PhraCate]
uniTwoTree t1 t2 = t1 ++ [x | x<-t2, elem x t1 /= True]

-- Find a phrase category by its (Start, Span). If does not, return []. 
findCate :: (Start, Span) -> [PhraCate] -> [PhraCate]
findCate (_, -1) _ = []      -- No categoy has span -1 or -2, used for finding parents.
findCate (_, -2) _ = []      -- For a leaf node, its non-existing parents have span -1 and -2.
findCate (st, sp) [] = []
findCate (st, sp) [x]
    | st == stOfCate x && sp == spOfCate x = [x]
    | otherwise = []
findCate (st, sp) (x:xs)
    | st == stOfCate x && sp == spOfCate x = x:(findCate (st, sp) xs)
    | otherwise = findCate (st, sp) xs

-- Find splited (namely parent) categories for a given phrase category from the closure of phrase categories. 
-- Here, every phrasal category in the closure satisfies its [category, tag, seman)] has only one tuple element.
findSplitCate :: PhraCate -> [PhraCate] -> [(PhraCate, PhraCate)]
findSplitCate pc phraCateClosure
    = [pct | pct <- pcTuples, cateComb (fst pct) (snd pct) == pc]
        where
        st1 = stOfCate pc
        st2 = ssOfCate pc
        sp1 = st2 - st1 - 1
        sp2 = spOfCate pc - sp1 - 1
        pcTuples = [(x, y) | x <- (findCate (st1, sp1) phraCateClosure), y <- (findCate (st2, sp2) phraCateClosure)] 
 
-- Find all growable tips of a tree from the closure of phrase categories.
-- Those nodes whose parents already exist in the tree can't grow again.
-- Those tips corresponding to initial categories are not growable.

findTipsOfTree :: [PhraCate] -> [PhraCate] -> [PhraCate]
findTipsOfTree [] _ = []
findTipsOfTree t phraCateClosure
    | ppcs == [] = findTipsOfTree (tail ot) phraCateClosure      -- Leaves have no parents and can't grow.
    | elem (snd (head ppcs)) ot = findTipsOfTree (tail ot) phraCateClosure  
                      -- Middle node which already grew. The right parent is in phrasal series ot.
    | otherwise = (head ot):findTipsOfTree (tail ot) phraCateClosure -- Middle node which doesn't yet grow.
       where
       ot = quickSort t    -- Such that there exists left parent << node << right parent for any node. 
       ppcs = findSplitCate (head ot) phraCateClosure    -- Find the parent pairs of node (head ot).
       
-- Find phrase categories with given span.
findCateBySpan :: Span -> [PhraCate] -> [PhraCate]
findCateBySpan sp  pcs = [x|x<-pcs, spOfCate x == sp]

-- Phrasal categories in a tree are divided into some lists, each of which includes 
-- those categories with same span, and every such list is arranged in ascending 
-- order on values of element Start, while these lists is arranged from 0 to 
-- (getNuOfInputCates - 1).

divPhraCateBySpan :: [PhraCate] -> [[PhraCate]]
divPhraCateBySpan t = map quickSort (map (\sp -> findCateBySpan sp t) [0..(getNuOfInputCates t - 1)])

-- Quick sort a list of phrasal categoies.
quickSort :: [PhraCate] -> [PhraCate]
quickSort [] = []
quickSort [x] = [x]
quickSort (x:xs) = (quickSort [y|y<-xs, pclt y x]) ++ [x] ++ (quickSort [y|y<-xs, pclt x y])



    
        
        
    


