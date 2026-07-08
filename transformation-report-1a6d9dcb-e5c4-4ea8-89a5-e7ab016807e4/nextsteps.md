# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removed several Windows-specific and legacy APIs. Run the .NET Upgrade Compatibility Analyzer or use the API compatibility tool to surface any runtime risks:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

Additionally, review any usage of the following common problem areas:
- `System.Web` (not available in .NET Core/.NET 5+)
- `BinaryFormatter` (disabled by default in .NET 5+)
- Windows Registry APIs (only available on Windows)
- `AppDomain.CreateDomain` (not supported)

## 5. Validate NuGet Package Compatibility

Check that all referenced NuGet packages support your target framework. Open the `.csproj` file and review each `<PackageReference>`. You can also inspect compatibility on [nuget.org](https://nuget.org) or run:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions compatible with your target framework.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and test the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that would not surface during a build.

```bash
dotnet run --configuration Release
```

Pay attention to:
- File path separators (`\` vs `/`)
- Case-sensitive file systems (Linux)
- Platform-specific dependencies or P/Invoke calls

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Review the contents of the `./publish` folder to confirm all required files are present before deploying to the target environment.