-- Cleaning and Transforming Data in SQL Queries

-- 1. View Raw Data
SELECT * FROM PortfolioProject.dbo.NashvilleHousing;

-- 2. Standardizing Date Format
ALTER TABLE NashvilleHousing ADD SaleDateConverted DATE;
UPDATE NashvilleHousing SET SaleDateConverted = CONVERT(DATE, SaleDate);

-- 3. Populate Missing Property Address Data
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

-- 4. Breaking Out Address into Separate Columns
ALTER TABLE NashvilleHousing ADD PropertySplitAddress NVARCHAR(255);
ALTER TABLE NashvilleHousing ADD PropertySplitCity NVARCHAR(255);
UPDATE NashvilleHousing SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);
UPDATE NashvilleHousing SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- 5. Splitting Owner Address into Address, City, and State
ALTER TABLE NashvilleHousing ADD OwnerSplitAddress NVARCHAR(255);
ALTER TABLE NashvilleHousing ADD OwnerSplitCity NVARCHAR(255);
ALTER TABLE NashvilleHousing ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);
UPDATE NashvilleHousing SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);
UPDATE NashvilleHousing SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- 6. Standardizing "Sold as Vacant" Field
UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

-- 7. Removing Duplicate Records
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
            ORDER BY UniqueID
        ) AS row_num
    FROM PortfolioProject.dbo.NashvilleHousing
)
DELETE FROM PortfolioProject.dbo.NashvilleHousing
WHERE UniqueID IN (
    SELECT UniqueID FROM RowNumCTE WHERE row_num > 1
);

-- 8. Removing Unused Columns
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;

-- 9. Importing Data Using OPENROWSET and BULK INSERT (Advanced)
-- Ensure the server is configured correctly before executing.

-- Enabling advanced options
-- EXEC sp_configure 'show advanced options', 1;
-- RECONFIGURE;
-- EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
-- RECONFIGURE;

-- Using BULK INSERT
-- BULK INSERT PortfolioProject.dbo.NashvilleHousing
-- FROM 'C:\Temp\NashvilleHousing.csv'
-- WITH (FIELDTERMINATOR = ',', ROWTERMINATOR = '\n');

-- Using OPENROWSET
-- SELECT * INTO NashvilleHousing
-- FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Path\To\File.xlsx', [Sheet1$]);
