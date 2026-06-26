# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages previously relied on Windows-specific APIs, verify that cross-platform alternatives are in place.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate compatibility concerns, even if they do not produce errors.

## 4. Run the Test Suite

If the solution contains unit or integration test projects, execute them:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests after migration may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime, such as:

- Changes in `System.Data` behavior
- Differences in ADO.NET provider availability
- Platform-specific path or encoding assumptions

## 5. Validate ADO.NET Functionality

Since the project is named `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- The database provider package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is referenced and up to date in the `.csproj` file.
- Connection strings are not hardcoded with Windows-specific authentication mechanisms (e.g., `Integrated Security=SSPI`) if the target deployment environment is non-Windows.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is reviewed, as these have limited or no support on non-Windows platforms.

## 6. Test on Target Platform

If the goal is cross-platform support, run and test the application on the intended non-Windows platform (Linux or macOS):

```bash
dotnet run --configuration Release
```

Pay attention to any runtime exceptions that may not have surfaced during the build, particularly around:

- File system path separators
- Case-sensitive file access on Linux
- Platform-specific API calls that throw `PlatformNotSupportedException`

## 7. Review Nullable Reference Type Warnings

Cross-platform .NET projects often enable nullable reference types by default. Check the `.csproj` for:

```xml
<Nullable>enable</Nullable>
```

If enabled, address any nullable warnings to improve code robustness.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your target runtime identifier (RID) as appropriate, such as `win-x64` or `osx-x64`. Review the publish output directory to confirm all required assets are present.