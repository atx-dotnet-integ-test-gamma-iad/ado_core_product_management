# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the value still references a Windows-only framework such as `net472` or `net48`, update it accordingly.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output and investigate any failures. Pay particular attention to tests that exercise data access or platform-specific behavior, as these areas are most likely to be affected by a migration from legacy .NET.

## 5. Check for Windows-Specific API Usage

Since this project is named `AdoCore` and likely involves ADO.NET data access, verify that any database drivers or providers in use are compatible with cross-platform .NET. Common areas to check:

- Confirm that the NuGet packages for your database provider (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are cross-platform compatible versions.
- Search the codebase for any usage of `System.Data.OleDb` or `System.Data.Odbc`, as these have limited or no support on non-Windows platforms.
- Check for any P/Invoke calls or `[DllImport]` attributes that reference Windows-specific native libraries.

## 6. Test on Target Platform

If the goal is to run on a non-Windows operating system, execute the build and tests on that platform directly:

```bash
dotnet build --configuration Release
dotnet test --configuration Release
```

This ensures there are no runtime issues that would not surface during a Windows build.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Review Output Artifacts

Inspect the publish output directory (typically `bin/Release/{tfm}/{rid}/publish/`) to confirm all expected assemblies, configuration files, and dependencies are present before deploying to the target environment.