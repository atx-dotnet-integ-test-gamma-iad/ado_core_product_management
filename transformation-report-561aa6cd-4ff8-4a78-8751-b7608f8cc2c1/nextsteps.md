# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build the Solution

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies in `AdoCore.csproj` are referencing versions compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available using:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address the underlying issues before proceeding.

## 5. Validate Runtime Behavior

Run the application locally and exercise its primary functionality:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Pay particular attention to:
- Database connectivity and ADO.NET operations, given the project name suggests ADO usage.
- Any file system paths that may have been hardcoded for Windows (e.g., backslashes in paths).
- Platform-specific API calls that may not behave identically on Linux or macOS.

## 6. Check for Windows-Specific Dependencies

Since this is a cross-platform migration, audit the code for any remaining Windows-specific dependencies such as:
- `Microsoft.Win32` namespace usage
- Windows registry access
- COM interop
- Windows-only NuGet packages

Use the .NET Compatibility Analyzer to assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

## 7. Publish the Application

Once validation is complete, publish the application for your target platform:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (includes the .NET runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed.

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm all expected files are present, then run the published output directly to validate it functions correctly outside of the development environment.