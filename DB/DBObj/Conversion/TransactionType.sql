USE iTRAAC
go

/*************** tblTransactionTypes */
ALTER TABLE tblTransactionTypes ADD Active bit NOT NULL DEFAULT (1)
ALTER TABLE tblTransactionTypes ADD SortOrder int NOT NULL DEFAULT (0)
ALTER TABLE tblTransactionTypes ADD ConfirmationText varchar (500) NULL
ALTER TABLE tblTransactionTypes ADD ExtendedFieldsCode varchar (50) NULL

