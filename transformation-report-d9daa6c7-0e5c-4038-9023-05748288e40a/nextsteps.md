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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

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

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address regressions introduced during the migration.

## 5. Check for Removed or Changed APIs

Cross-platform .NET removes certain APIs that were available in .NET Framework. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any runtime-level incompatibilities that would not surface as build errors:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific registry or file path assumptions
- `AppDomain` and remoting APIs

## 6. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended platform (Windows, Linux, macOS) to catch platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

Verify that file paths, line endings, and any platform-specific behaviors function correctly on each target OS.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

**Framework-dependent deployment:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained deployment (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to your target environment.