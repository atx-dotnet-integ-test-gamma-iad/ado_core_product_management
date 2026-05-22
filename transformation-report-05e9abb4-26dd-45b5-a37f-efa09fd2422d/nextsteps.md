# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Verify that no warnings or errors appear in the output. Pay attention to any `NU` prefixed NuGet warnings, as they may indicate package compatibility issues that did not surface as hard errors.

## 3. Check for Windows-Only API Usage

Even without build errors, the code may contain calls to Windows-only APIs (e.g., registry access, `System.Windows.Forms`, COM interop, or `System.Drawing` GDI+). Run the .NET compatibility analyzer to surface any such issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Review any `PC001` or `PC002` analyzer warnings that are reported.

## 4. Run Existing Tests

If the solution contains test projects, execute them to confirm runtime behavior is consistent with the original:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review all test results and investigate any failures. A passing build does not guarantee correct runtime behavior, particularly around areas such as:

- File path separators (`\` vs `/`)
- Case-sensitive file systems on Linux/macOS
- Platform-specific environment variables or configuration paths

## 5. Validate ADO (ActiveX Data Objects) / Data Access Behavior

Given the project is named `AdoCore`, it likely involves data access. Confirm the following:

- Any previous usage of `System.Data.OleDb` has been replaced or is explicitly supported. Note that `System.Data.OleDb` is Windows-only on .NET Core/.NET 5+.
- Connection strings are stored in configuration files (e.g., `appsettings.json`) rather than hardcoded.
- Database providers (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are referencing their latest stable NuGet packages compatible with your target framework.

## 6. Review NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure no packages are pinned to versions that only support .NET Framework. You can check compatibility at [nuget.org](https://www.nuget.org) or by running:

```bash
dotnet list package --outdated
```

Update packages where appropriate.

## 7. Test on Target Platform

If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that static analysis may not detect:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate RID for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output folder before deploying to the target environment.