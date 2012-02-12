USE [iTRAAC]
GO
/****** Object:  StoredProcedure [dbo].[cp_parmsel_TaxFormData_ABW]    Script Date: 01/04/2012 10:13:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[cp_parmsel_TaxFormData_ABW]
@TaxFormID INT,
@SignAgentID INT = 0
AS begin

SET NOCOUNT ON

-- Final output table
CREATE TABLE #FormData (FDID INT IDENTITY(1,1), DATA VARCHAR(512))

-- SET UP THE FormTypeID VAR
DECLARE @FormTypeID INT
SET @FormTypeID = 3 -- <--- ABW TAXFORM TYPE

--if non-existant @TaxFormID, print test data
IF NOT EXISTS(SELECT 1 FROM tblTaxForms WHERE TaxFormID = @TaxFormID) begin
  INSERT #FormData (DATA)
  SELECT dbo.GetFieldSpecs(@FormTypeID, RTRIM(FieldName))+REPLICATE('ABW:'+RTRIM(FieldName)+':', 14) 
  FROM tblFormFields 
  WHERE FormTypeID = @FormTypeID
  ORDER BY CONVERT(INT, SUBSTRING(fieldname, 2,2))
END

--otherwise, gather data from central view "vw_ABW" 
ELSE begin
  SELECT * INTO #TT FROM vw_ABW WHERE TaxFormID=@TaxFormID

  --pivot columnar data from vw_ABW into #FormData rows to feed the form printing routine in the VB6 client app
  DECLARE @FieldName VARCHAR(50)
  DECLARE curs CURSOR LOCAL FAST_FORWARD for
    SELECT [NAME] FROM tempdb..syscolumns WHERE id = OBJECT_ID('tempdb..#tt') AND NAME LIKE 'f[0-9]%' ORDER BY CONVERT(INT, SUBSTRING([name], 2, 2))
  OPEN curs
  WHILE(1=1) BEGIN
    FETCH NEXT FROM curs INTO @FieldName
    IF (@@FETCH_STATUS <> 0) BREAK

    INSERT #FormData (Data)
    EXEC('SELECT dbo.GetFieldSpecs('+@FormTypeID+', '''+@FieldName+''')+'+@FieldName+' FROM #tt')
  END
  DEALLOCATE curs

  DROP TABLE #TT
  
  --bja: important business rule:
  --only certain authorized persons should print in the VAT officers signature block
  --vw_ABW provides the selling agent's SigBlock by default
  --but the person selling the form is often _NOT_ the authorized signer
  --and therefore the supplied @SignAgentID takes precedence 
  --specified in iTRAAC > Tools > Options > General > SigBlock dropdown... 
  --this data is saved in the local registry under HKEY_CURRENT_USER\Software\VB and VBA Program Settings\iTRAAC Console\Options
  --therefore it is both computer and login specific, i.e. not specified in the DB
  --consider 'hacking' the iTRAAC > Tools > Options > Local Database Settings > Approver's SigBlock fields
  --since those don't appear to be actively used for any live functionality
  DECLARE @SigBlock VARCHAR(1000)
  SELECT @SigBlock = SigBlock FROM tblTaxFormAgents WHERE AgentID = @SignAgentID
  IF (@SigBlock IS NOT NULL)
    UPDATE #FormData SET DATA = dbo.GetFieldSpecs(@FormTypeID, 'F24')+@SigBlock WHERE FDID = 24

END

SELECT * FROM #FormData
DROP TABLE #FormData

end
