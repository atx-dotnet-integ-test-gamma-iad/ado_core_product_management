# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility shims being used silently.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been replaced with compatibility shims or may behave differently at runtime. Review the code for usage of the following areas, which commonly differ between .NET Framework and modern .NET:

- `System.Web` (not available in cross-platform .NET)
- `AppDomain` (limited support)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `System.Drawing` (requires the `System.Drawing.Common` NuGet package and may have OS restrictions)
- `BinaryFormatter` (disabled by default in .NET 5+)
- WCF server-side components (not supported; client-side available via `System.ServiceModel` packages)

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. For each package, confirm the version being referenced supports your target framework. Use [NuGet.org](https://www.nuget.org) to verify compatibility.

```bash
dotnet list package --outdated
```

Update any outdated packages that now have versions with native cross-platform support.

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any OS-specific runtime issues that would not surface during a build:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`\` vs `/`)
- Case sensitivity in file system access (Linux is case-sensitive)
- Environment variable differences

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your target environment (e.g., `win-x64`, `osx-x64`). For a framework-dependent deployment, omit `--self-contained`:

```bash
dotnet publish --configuration Release -o ./publish
```

Review the contents of the `./publish` directory to confirm all expected output files are present before deploying to the target environment.