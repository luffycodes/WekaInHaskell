module NaiveBayes.NaiveBayes (
        NaiveBayes(..),
        display,
        fit,
        posterior,
        predict,
	predictMulti,
) where

import Structures.Structures
import Structures.GeneralAux
import NaiveBayes.Distributions
import Data.List
import Control.Applicative

{- |
 This is a NaiveBayes object. It stores the classnames, priorprobabilities, distribution, dimensions,
 PosteriorFunctions are the list of probes for each of the features

-}
data NaiveBayes = NaiveBayes {
                                cNames :: [ClassName]    -- Class names
                                ,cPrior	    :: [(ClassName,Probability)]    -- Class priors
                                ,dist	    :: Distribution    -- Distribution names
                                ,nClasses     :: Int    -- Number of classes
                                ,nDims	    :: Int    -- Number of dimensions
                                ,posteriorFunctions :: [Probe]-- array of posterior functions
                             }
instance (Show NaiveBayes) where
        show nb = let 
                        s1 = "classes : " ++ (show $ cNames nb)
                        s2 = "distribution : " ++ (show $ dist nb)
                        s3 = "Dimension : "  ++ (show $ nDims nb)
                  in 
                        s1++ "\n" ++s2 ++ "\n" ++ s3 ++ "\n"


{- fit : Start
-}

{- | fits the given data set to give the naive bayes object
-}
fit :: PriorType -> Distribution -> DataSet -> NaiveBayes

fit priors distribution dataset = NaiveBayes cNames' cPrior' dist' nClasses' nDims' posteriorFunctions'
              where
                cNames' = cNamesFinder dataset 
                cPrior'= cPriorFinder priors dataset 
                dist' = distribution 
                nClasses' = length cNames' 
                nDims' = nDimsFinder dataset
                posteriorFunctions' = posteriorFunctionsFinder distribution dataset

-- cNamesFinder 
cNamesFinder :: DataSet -> [ClassName]
cNamesFinder dataset = removeDuplicates $ classes dataset

--nDimsFinder
nDimsFinder dataset = length ((points dataset) !! 0)

-- PriorFinder : Start
cPriorFinder :: PriorType -> DataSet -> [(ClassName,Probability)]
cPriorFinder priors dataset = case priors of 
                                        Empirical -> empiricalPriorFinder dataset
                                        Uniform -> uniformPriorFinder dataset
                                        Specific list -> list

empiricalPriorFinder :: DataSet -> [(ClassName,Probability)]
empiricalPriorFinder dataset = ehelper1 cNames cdata
                               where
                                cNames = cNamesFinder dataset
                                cdata = classes dataset
                                total = fromIntegral $ length  $ classes dataset
                                ehelper1 [] _ = []
                                ehelper1 (c:cs) cdata = (c,prob): rest 
                                                         where
                                                           rest = ehelper1 cs cdata
                                                           prob = (fromIntegral (count c cdata)) / total
uniformPriorFinder :: DataSet -> [(ClassName,Probability)]
uniformPriorFinder dataset = f <$> classes
                             where 
                                classes = cNamesFinder dataset
                                prob = 1 / (fromIntegral (length classes))
                                f x = (x,prob)
-- PriorFinder : End
posteriorFunctionsFinder :: Distribution -> DataSet -> [Probe]

posteriorFunctionsFinder distribution dataset = 
                                                                 posteriorFunctionsFinder' distfinal dataset
                                                                 where
                                                                        ndims = nDimsFinder dataset
                                                                        distfinal = case distribution of
                                                                                           Single d -> take ndims $ repeat d
                                                                                           Multiple lds -> lds

posteriorFunctionsFinder' ::[DistributionType] -> DataSet -> [Probe]
posteriorFunctionsFinder' distfinal dataset = 
                                                                collectprobes allFeatureData distfinal classdata
                                                                where
                                                                        allFeatureData = transpose $ points dataset
                                                                        classdata = classes dataset
collectprobes :: [FeatureData] -> [DistributionType] -> ClassData -> [Probe]
collectprobes [] _ _ = []
--collectprobes _ [] _ = []
collectprobes (fd:fds) (dt:dts) cd = (giveProbe dt fd cd) : collectprobes fds dts cd
                                                                

giveProbe :: DistributionType -> FeatureData -> ClassData -> Probe
giveProbe dt fd cd = case dt of
                Normal -> giveGaussianProbe fd cd
                _ -> error "Only Gaussian Probe Implemented!"

{- fit : End -}
{- Posterior : Start -}

{- theory
posterior = p(class/featurevector) = p (class) * \pi (p (feature/class) / p(featurevector)
-}

-- | Finds the probability of the featurevector for a given naive bayes object
posterior :: NaiveBayes -> FeatureVector -> ClassName -> Probability

posterior nb fvector cname =  prior * product
                                where
                                  condprobvector = giveCondProbVector nb fvector cname
                                  prior = getFromTupleList cname (cPrior nb)
                                  product = productList condprobvector
                                  


giveCondProbVector  nb fvector cname =  condprobvector
                                        where
                                                probevector = posteriorFunctions nb
                                                cnamevector = take (nDims nb) $ repeat cname
                                                ZipList condprobvector = ZipList probevector <*> ZipList cnamevector <*> ZipList fvector


{- Posterior : End -}

display :: NaiveBayes -> IO ()
display nb = do
                putStrLn ("ClassNames : " ++ show (cNames nb))
                putStrLn ("NDims : " ++ show (nDims nb))
                putStrLn ("Distribution " ++ show (dist nb))

-- | Predicts the class a particular data point belongs to given the naive bayes object
predict :: NaiveBayes -> FeatureVector -> ClassName
predict nb fvector =    maxRet1 cnames probabilities
                        where
                        cnames = cNames nb
                        probabilities = (posterior nb fvector) <$> cnames

-- | predicts the classes for a list of feature vectors
predictMulti :: NaiveBayes -> [FeatureVector] -> [ClassName]

predictMulti nb listfv = map (predict nb) listfv

input1 = [
                [5.9,180,12],
                [6,190,11],
                [6,170,12],
                [6.1,100,6],
                [3.9,165,10],
                [4,150,8],
                [4,130,7],
                [4.1,150,9]
                                        ]

cdt = ["boys","boys","boys","boys","girls","girls","girls","girls"]
dataset1 = DataSet input1 cdt


input2 = [
		[1],
		[2],
		[3],
		[4],
		[5],
		[6],
		[7],
		[8],
		[9],
		[10]
			]
cdt2 = ["a","b","c","d","e","f","g","h","i","j"];
dataset2 = DataSet input2 cdt2
