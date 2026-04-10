# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime version installed on your machine.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version mismatches.

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate subtle compatibility issues.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that runtime behavior matches expectations from the original .NET Framework version:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and modern .NET, such as changes in:
- `System.Data` ADO.NET behavior
- Connection string handling
- Exception types or messages

## 5. Validate ADO.NET Functionality

Since this project is named `AdoCore`, it likely contains database access code. Manually verify the following:

- **Connection strings** are correctly configured for the target environment.
- **Database provider packages** (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are the correct versions for modern .NET.
- **`System.Data` usages** behave as expected, particularly around `DataSet`, `DataTable`, and `DataReader` operations, which can have subtle differences on modern .NET.

## 6. Check for Removed or Changed APIs

Run the .NET Upgrade Assistant compatibility analyzer or the `ApiCompat` tool to surface any API usage that may compile but behave differently at runtime:

```bash
dotnet tool install -g dotnet-apicompat
```

Alternatively, review the [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) relevant to your source and target framework versions.

## 7. Test Against a Real Database

Execute integration-level tests or manual tests against an actual database instance to confirm:

- Queries return expected results.
- Transactions commit and roll back correctly.
- Connection pooling behaves as expected.

## 8. Review Configuration Files

Ensure that any configuration previously held in `App.config` or `Web.config` has been migrated to `appsettings.json` or environment variables, as modern .NET does not use the legacy configuration system by default.

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "your-connection-string-here"
  }
}
```

## 9. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the output directory contains all required files and that the application runs correctly from the published output on the target machine.