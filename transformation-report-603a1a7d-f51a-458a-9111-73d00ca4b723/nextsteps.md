# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a full package restore to ensure all NuGet dependencies are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about packages that are deprecated, unlisted, or incompatible with the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate compatibility concerns, even if they are not hard errors.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that runtime behavior has not changed during the transformation:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding. Pay particular attention to tests that cover data access logic, as `AdoCore` suggests ADO.NET usage, which can have platform-specific behavior differences.

## 5. Validate ADO.NET Functionality

Since the project name suggests ADO.NET usage, manually verify the following:

- **Connection strings** are correctly configured for the target environment. Cross-platform .NET may require different connection string formats or drivers depending on the database (e.g., SQL Server requires `Microsoft.Data.SqlClient` rather than `System.Data.SqlClient`).
- **NuGet package references** use the cross-platform compatible versions. For SQL Server, confirm `Microsoft.Data.SqlClient` is referenced instead of the legacy `System.Data.SqlClient`.
- **Windows-specific APIs** such as Windows Authentication or MSDTC (distributed transactions) are either replaced or confirmed to be available in the target deployment environment.

## 6. Check for Removed or Changed APIs

Run the .NET Upgrade Assistant compatibility analyzer or the `dotnet-compatibility` tool to surface any API usage that may behave differently at runtime on non-Windows platforms:

```bash
dotnet tool install -g dotnet-compatibility
```

Alternatively, review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for any breaking changes relevant to your previous framework version.

## 7. Test on Target Platform

If the goal is cross-platform execution, run and validate the application on the intended non-Windows operating system (Linux or macOS) to catch any remaining platform-specific issues that do not surface as build errors:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (RID) for your deployment target. Use `--self-contained true` if the .NET runtime will not be pre-installed on the target machine.

Review the publish output directory to confirm all required assets and configuration files are present before deploying.