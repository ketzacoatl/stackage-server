module Types where

import ClassyPrelude.Yesod
import Data.BlobStore (ToPath (..))
import Text.Blaze (ToMarkup)
import Database.Persist.Sql (PersistFieldSql)
import qualified Data.Text as T

newtype PackageName = PackageName { unPackageName :: Text }
    deriving (Show, Read, Typeable, Eq, Ord, Hashable, PathPiece, ToMarkup)
newtype Version = Version { unVersion :: Text }
    deriving (Show, Read, Typeable, Eq, Ord, Hashable, PathPiece, ToMarkup)
newtype PackageSetIdent = PackageSetIdent { unPackageSetIdent :: Text }
    deriving (Show, Read, Typeable, Eq, Ord, Hashable, PathPiece, ToMarkup, PersistField, PersistFieldSql)

data PackageNameVersion = PackageNameVersion !PackageName !Version
    deriving (Show, Read, Typeable, Eq, Ord)

instance PathPiece PackageNameVersion where
    toPathPiece (PackageNameVersion x y) = concat [toPathPiece x, "-", toPathPiece y]
    fromPathPiece t' | Just t <- stripSuffix ".tar.gz" t' =
        case T.breakOnEnd "-" t of
            ("", _) -> Nothing
            (_, "") -> Nothing
            (T.init -> name, version) -> Just $ PackageNameVersion (PackageName name) (Version version)
    fromPathPiece _ = Nothing

data StoreKey = HackageCabal !PackageName !Version
              | HackageSdist !PackageName !Version
              | CabalIndex !PackageSetIdent
              | CustomSdist !PackageSetIdent !PackageName !Version

instance ToPath StoreKey where
    toPath (HackageCabal name version) = ["hackage", toPathPiece name, toPathPiece version ++ ".cabal"]
    toPath (HackageSdist name version) = ["hackage", toPathPiece name, toPathPiece version ++ ".tar.gz"]
    toPath (CabalIndex ident) = ["cabal-index", toPathPiece ident ++ ".tar.gz"]
    toPath (CustomSdist ident name version) =
        [ "custom-tarball"
        , toPathPiece ident
        , toPathPiece name
        , toPathPiece version ++ ".tar.gz"
        ]

newtype HackageRoot = HackageRoot { unHackageRoot :: Text }
    deriving (Show, Read, Typeable, Eq, Ord, Hashable, PathPiece, ToMarkup)

class HasHackageRoot a where
    getHackageRoot :: a -> HackageRoot
instance HasHackageRoot HackageRoot where
    getHackageRoot = id
