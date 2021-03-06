module NaiveBayes.NaiveBayesInterface(
        crossValidate,
	traintest,
	makeObjectFromFile,
)
where

import NaiveBayes.NaiveBayes
import Structures.GeneralAux
import Data.List
import Structures.Structures
import NaiveBayes.Distributions
import Control.Applicative
import Structures.Definitions

-- | Takes the data from a file and fits it with the given priortype and distribution to give IO (naive bayes object)
makeObjectFromFile :: PriorType -> Distribution -> FilePath -> IO NaiveBayes
makeObjectFromFile pt ds fp = do
                                   rawdata <- readFile fp
                                   let
                                        dataset = convertToDataSet rawdata
                                   
                                   return $ fit pt ds dataset

-- | converts the data in csv format to  DataSet
convertToDataSet :: String -> DataSet
convertToDataSet str = DataSet features classes
		where
			(features,classes) = breakup (split '\n' str)

breakup :: [String] -> ([FeatureVector],[ClassName])
breakup list = foldr f ([],[]) list
		where 
			f str (fv,cn) = (fvnew,cnnew)
				where
					vals = split ',' str
					cnnew = cn++[last vals]
					vs = take ((length vals)-1) vals
					fvector = map (read) vs
					fvnew = fv ++ [fvector]

-- | converts the data in csv format to list of feature vector
convertToFeatureVectorSet :: String -> [FeatureVector]

convertToFeatureVectorSet str = let 
					firstsplit =  split '\n' str
					secondsplit = map (split ',') firstsplit
				in 
					map (map read) secondsplit



-- | trains the classifier on the train file and tests it on the test file and writes the classes in a file
traintest :: PriorType -> Distribution -> TrainPath -> TestPath-> String ->  IO()

traintest pt ds trainpath testpath clspath = 
						do
					   		rawtraindata <- readFile trainpath
							rawtestdata <- readFile testpath
							let
							  traindataset = convertToDataSet rawtraindata
							  testdataset = convertToFeatureVectorSet rawtestdata
							  nb = fit pt ds traindataset
							  classes = predictMulti nb testdataset
							  classdata = intercalate "\n" classes
							writeFile clspath classdata
						


-- |crossValidates the given file and returns the performace of the classfier
crossValidate :: Double -> PriorType -> Distribution -> FPath -> IO Performance
crossValidate ratio pt ds fp = do
					rawdata <- readFile fp
					let
						 dataset = convertToDataSet rawdata
					return (crossValidateData ratio pt ds dataset)

-- |crossValidate the data and returns the performace of the classifier
crossValidateData :: Double -> PriorType -> Distribution -> DataSet -> Performance
crossValidateData ratio pt ds dataset = let
					instances = splitDataSet ratio dataset
					results = (checkPerformance pt ds) <$> instances
					(correct,total) = foldr f (0,0) results
							  where	
								f (_,(a,b)) (at,bt) = (a+at,b+bt)
				    in 
					(correct,total)



-- | takes out a slice from the Dataset


slice :: DataSet -> (Int,Int) -> (DataSet,DataSet)

slice (DataSet ftvs clss) (start,end) 	| start >= (length ftvs) = error "sizes dont match"
					| otherwise = (dstrain,dstest)
							where
								fvstrain1 = take start ftvs
								clstrain1 = take start clss
								fvstrain2 = drop (end+1) ftvs
								clstrain2 = drop (end+1) clss
								fvstest = take (end - start+1) $ drop start ftvs
								clstest = take (end - start+1) $ drop start clss
								dstrain = DataSet (fvstrain1++fvstrain2) (clstrain1 ++ clstrain2)
								dstest = DataSet fvstest clstest



-- (traindataset, testdataset) -> (testdataset,performace)
-- | Trains the classifier on the first element of the tuple and tests it on the second dataset .. returns the performace
checkPerformance :: PriorType -> Distribution -> (DataSet,DataSet) -> (DataSet,Performance)
checkPerformance pt ds (train,test) =  	let
						nb = fit pt ds train
						DataSet testfv testcl = test
						predictcls = predictMulti nb testfv
						ZipList eq = (==) <$> (ZipList predictcls) <*> (ZipList testcl)
						count = length $ filter (\x->x==True) eq
					in
						(test,(count,length testfv))

-- | splits the dataset into testing instances during crossvalidation

splitDataSet :: Double -> DataSet -> [(DataSet,DataSet)]
splitDataSet ratio dataset = let 
					size = decidesize ratio $ length $ classes dataset
					count = gif (length (classes dataset))  size
					base = [0..(count-1)]
					start = (* size) <$> base
					end = (+(size-1)) <$> start
					slices = zip start end
			     in
					(slice dataset) <$> slices


decidesize r total = floor (r*(fromIntegral total))
				
 
gif val div = ceiling ((fromIntegral val) / (fromIntegral div))

					
						

												
