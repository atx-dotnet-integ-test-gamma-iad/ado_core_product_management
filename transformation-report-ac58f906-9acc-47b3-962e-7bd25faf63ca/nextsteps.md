# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Example:

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific API Usage

Even without build errors, certain APIs that were available in .NET Framework may behave differently or be absent at runtime in cross-platform .NET. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for potential issues:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Web` references
- Windows Registry access
- COM interop
- `AppDomain` usage
- `BinaryFormatter`

## 5. Validate NuGet Package Compatibility

Review all NuGet packages referenced in `AdoCore.csproj` and confirm each one targets `netstandard2.0`, `netstandard2.1`, or the specific .NET version you are targeting. Replace any packages that only support `net4x` with their cross-platform equivalents.

```bash
dotnet list package --outdated
```

## 6. Run the Application and Perform Smoke Testing

Execute the application and perform basic functional validation:

```bash
dotnet run --configuration Release --project AdoCore.csproj
```

Walk through the primary use cases of the application to confirm runtime behavior matches expectations from the legacy version.

## 7. Review Output Artifacts

Publish the project to confirm the output is complete and self-contained if needed:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to verify all expected assemblies, configuration files, and assets are present.

## 8. Address Any Runtime Warnings or Deprecations

After running the application, review the console output and application logs for any runtime warnings related to obsolete APIs or behavioral changes introduced in the target .NET version. Address these proactively to avoid future compatibility issues.